import sys
import os
import httpx

from services import args_to_use, Service


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
                    "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
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
        # TODO add request builder to make separate requests/reponses for custom APIs
        body = {
            "model": use.model,
            "messages": [
                {
                    "role": "user", # TODO use system for openai compat, use "user" for claude, for now all can use user too
                    "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            "max_tokens":200,
            # "n":1  # default # claude chokes on this, don't need it anyways, its default on openai API
        }
        chat_url = use.chat_url()
        headers = {
            "Authorization": f"Bearer {use.api_key}", # TODO openai compat only, remove for claude (though doesn't hurt claude currently)
            "x-api-key": f"{use.api_key}", # TODO claude only, take off for openai compat (works with openai currently)
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01", # TODO claude only, take off for openai compat (works w/ openai currentlY)
        }
        response = http_client.post(chat_url, json=body, headers=headers)
        response.raise_for_status()
        completion = response.json()
        if "content" in completion:
            # TODO claude parser only
            content = completion["content"][0]["text"]
        else:
            # TODO openai parser only
            content = completion["choices"][0]["message"]["content"]
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
