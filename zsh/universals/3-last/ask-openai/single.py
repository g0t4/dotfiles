import json
import os
import sys
import time

from chat_non_stream import GenerationResult, generate_non_streaming
from services import get_selected_service_for_args

# FYI this is a fallback for when you do not have iterm2 available.
#  i.e. on windows
#  this is integrated into each shell via a widget/keymap/bind in pwsh/zsh/fish
#  IOTW I really don't need this on my Mac
#  nor do I need this when remoting over SSH from iterm2 on my mac
#  only if I am say logged into a windows machine directly (or an arch desktop)
#   then I have to use ctrl+b too to activate this
#   this was my OG OG ask-openai plugin core

system_message = "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
max_tokens = 2000

# Directory for fish shell traces (mirrors nvim plugin's trace dir)
FISH_TRACE_DIR = os.path.expanduser("~/.local/state/nvim/ask-openai/fish")


def build_trace_data(
    unix_timestamp: int,
    messages: list[dict],
    generation_result: GenerationResult,
    service_flag: str | None,
    user_input: str,
) -> dict:
    """Build the trace data object to save to disk.

    Structure mirrors ask-openai.nvim's completion_logger.lua format for consistency,
    but with fish-shell-specific fields added at top level.
    """
    # Build messages array from what we know
    trace_messages = [
        {"role": "system", "content": system_message},
        {"role": "user", "content": user_input},
    ]

    # Add assistant message with content and any reasoning if available
    assistant_entry: dict[str, str] = {"role": "assistant", "content": generation_result.content}
    if generation_result.raw_ai_message is not None:
        # Check for reasoning_content in response_metadata (used by some models like deepseek)
        raw_metadata = generation_result.response_metadata
        if isinstance(raw_metadata, dict):
            if "reasoning_content" in raw_metadata:
                assistant_entry["reasoning_content"] = raw_metadata["reasoning_content"]
            # Also check for finish_reason
            if "finish_reason" in raw_metadata:
                assistant_entry["finish_reason"] = raw_metadata["finish_reason"]

    trace_messages.append(assistant_entry)

    # Build the response object from response_metadata
    # This captures token usage, timings, and other useful data
    response_data: dict = {}
    if generation_result.response_metadata:
        response_data = dict(generation_result.response_metadata)

    # Add model info that might not be in response_metadata
    response_data["model"] = generation_result.model
    response_data["service"] = generation_result.service_name

    trace_data: dict = {
        "session_id": unix_timestamp,
        "messages": trace_messages,
        "response": response_data,
    }

    # Add optional service flag if provided
    if service_flag is not None:
        trace_data["service_flag"] = service_flag

    return trace_data


def save_trace_file(trace_data: dict) -> str | None:
    """Save trace data to disk and return the file path, or None on failure."""
    try:
        os.makedirs(FISH_TRACE_DIR, exist_ok=True)
    except OSError as e:
        print(f"Warning: could not create trace dir {FISH_TRACE_DIR}: {e}", file=sys.stderr)
        return None

    unix_timestamp = trace_data["session_id"]
    trace_filename = f"{unix_timestamp}-trace.json"
    trace_path = os.path.join(FISH_TRACE_DIR, trace_filename)

    try:
        with open(trace_path, "w", encoding="utf-8") as trace_file:
            json.dump(trace_data, trace_file, indent=2, ensure_ascii=False)
        return trace_path
    except OSError as e:
        print(f"Warning: could not write trace file {trace_path}: {e}", file=sys.stderr)
        return None


def main():
    stdin_context = sys.stdin.read()

    # Parse service args from command line (first arg after script name)
    service_flag = sys.argv[1] if len(sys.argv) > 1 else None

    generation_result = generate_non_streaming(stdin_context, system_message, max_tokens)

    if generation_result.content.startswith("ABORT") or generation_result.content.startswith("Error"):
        # Print error to stderr so fish can capture it
        print(generation_result.content, file=sys.stderr)
        sys.exit(1)

    # Capture unix timestamp for trace
    current_timestamp = int(time.time())

    # Build and save trace
    user_input_from_context = stdin_context.split("\n", 1)[-1] if "\n" in stdin_context else stdin_context
    trace_data = build_trace_data(
        unix_timestamp=current_timestamp,
        messages=[],  # build_trace_data constructs messages internally
        generation_result=generation_result,
        service_flag=service_flag,
        user_input=user_input_from_context,
    )

    saved_path = save_trace_file(trace_data)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(generation_result.content)


if __name__ == "__main__":
    main()
