import argparse
import sys
import platform
from os import getenv
import keyring
from openai import OpenAI
from keyrings.cryptfile.cryptfile import CryptFileKeyring

from services import use_openai, use_lmstudio, use_groq, use_ollama, Service


def generate_completions(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        # one line per completion, tab delimits choice/description (description is optional)
        # print(f"foo\tthe foo choice")
        # print(f"bar\tthe bar choice")

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a command line completion expert, I will provide you with the current command I am typing, I need you to provide completions as if you were registered as a completion script. Return each completion on its own line. Each response line is formatted as: <completion><tab><description> where <description> is optional. Do not inclue <tab> if not including a <description>. Only return the <completion> token for the next choice and not for the entire command line. Return NOTHING ELSE."
                    # TODO examples? for like curl?
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            max_tokens=120,
            n=1  # default
        )

        response = completion.choices[0].message.content

        log_response(passed_context, use, response)

        print(response)
    except Exception as e:
        print(f"{e}")
        return None


def log_response(passed_context: str, use: Service, response: str):
    log_file = f"{getenv('HOME')}/.ask.openai.completer.log"
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument('--dump_config', action='store_true', default=False)
    parser.add_argument('--openai', action='store_true', default=False)
    parser.add_argument('--lmstudio', action='store_true', default=False)
    parser.add_argument('--groq', action='store_true', default=False)
    parser.add_argument('--ollama', action='store_true', default=False)
    # optional model name (for all services):
    parser.add_argument("model", type=str, const=None, nargs='?')
    #
    args = parser.parse_args()

    # PRN pass model parameter if can be overriden per service (like w/ ollama)
    if args.groq:
        use = use_groq(args.model)
    elif args.lmstudio:
        use = use_lmstudio(args.model)
    elif args.ollama:
        use = use_ollama(args.model)
    else:
        use = use_openai(args.model)

    if args.dump_config:
        # print(args)
        print(use)
        exit(0)

    stdin_context = sys.stdin.read()
    # empty context usually generates echo hello :) so allow it

    if "question: dump\n" in stdin_context:
        # dump context to troubleshoot
        print(stdin_context)
        sys.exit(2)

    generate_completions(stdin_context, use)


if __name__ == "__main__":
    main()
