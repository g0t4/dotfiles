import argparse
import sys
from os import getenv
from openai import OpenAI

from services import args_to_use, use_openai, use_lmstudio, use_groq, use_ollama, Service


def generate_command(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
                # PRN can I improve phi3/mixtral by further telling it not to give me an explanataion, i.e.:
                # {
                #     "role": "system",
                #     "content": "The command line is:"
                # }
            ],
            max_tokens=80,
            n=1  # default
        )

        response = completion.choices[0].message.content
        # log responses to ~/.ask.openai.log

        log_response(passed_context, use, response)

        return response
    except Exception as e:
        print(f"{e}")
        return None


def log_response(passed_context: str, use: Service, response: str):
    log_file = f"{getenv('HOME')}/.ask.openai.log"
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


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
