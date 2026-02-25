import sys
from chat_non_stream import generate_non_streaming

system_message = "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
max_tokens = 200

def main():

    stdin_context = sys.stdin.read()

    command = generate_non_streaming(stdin_context, system_message, max_tokens)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)

if __name__ == "__main__":
    main()
