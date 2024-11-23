import sys
import os
import httpx

from services import args_to_use, Service


system_message = "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"

def generate_command(passed_context: str, use: Service):
    if use.name == "anthropic":
        return get_anthropic_suggestion(passed_context, use)
    else:
        return get_openai_suggestion(passed_context, use)

def get_openai_suggestion(passed_context: str, use: Service):
    http_client = httpx.Client()
    try:
        body = {
            "model": use.model,
            "messages": [
                {
                    "role": "system",
                    "content": system_message
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            "max_tokens":200,
            "n":1 # default
        }
        chat_url = use.chat_url()
        headers = {
            "Authorization": f"Bearer {use.api_key}",
            "Content-Type": "application/json",
        }
        response = http_client.post(chat_url, json=body, headers=headers)
        response.raise_for_status()
        completion = response.json()
        content = completion["choices"][0]["message"]["content"]
        log_response(passed_context, use, content)
        return content
    except Exception as e:
        print(f"{e}")
        return None


def get_anthropic_suggestion(passed_context: str, use: Service):
    http_client = httpx.Client()
    try:
        # https://docs.anthropic.com/en/api/messages
        body = {
            "system": system_message,
            "model": use.model,
            "messages": [
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            "max_tokens":200,
        }
        chat_url = use.chat_url()
        headers = {
            "x-api-key": f"{use.api_key}",
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01",
        }
        response = http_client.post(chat_url, json=body, headers=headers)
        response.raise_for_status()
        completion = response.json()
        content = completion["content"][0]["text"]
        log_response(passed_context, use, content)
        return content
    except Exception as e:
        print(f"{e}")
        return None


def log_response(passed_context: str, use: Service, response: str):
    log_file = os.path.join(os.path.expanduser("~"), ".ask.single.log")
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.name} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


def main():

    use = args_to_use()

    stdin_context = sys.stdin.read()
    # empty context usually generates echo hello :) so allow it

    if "question: dump\n" in stdin_context:
        # dump context to troubleshoot
        print(stdin_context)
        sys.exit(2)

    command = generate_command(stdin_context, use)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)


if __name__ == "__main__":
    main()
