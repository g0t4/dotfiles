import argparse
import sys
import platform
from os import getenv
from collections import namedtuple
import keyring
from openai import OpenAI
from keyrings.cryptfile.cryptfile import CryptFileKeyring

Service = namedtuple('Service', 'base_url model api_key name')
Service.__repr__ = lambda self: f"Service({self.name} model={self.model})"  # i.e. printing (logging), DO NOT INCLUDE api_key


def use_groq(model: str):

    return Service(
        name='groq',
        api_key=get_api_key('groq', 'ask'),
        base_url='https://api.groq.com/openai/v1',
        model=model if model else 'llama3-70b-8192',
        # groq https://console.groq.com/docs/models
        #   llama3-8b-8192, llama3-70b-8192, mixtral-8x7b-32768, gemma-7b-it
    )


def use_openai(model: str):

    # *** gpt 4:
    # openai https://platform.openai.com/docs/models
    # model = "gpt-4o"  # thru Oct 2023 # currently evaluating
    # model = "gpt-4-turbo" # currently => "gpt-4-turbo-2024-04-09"
    # model = "gpt-4-turbo-preview"  # currently => "gpt-4-0125-preview" (last used before gpt-4o)
    # model = "gpt-4-1106-preview", # thru Apr 2023 - aka gpt4 turbo # *** first model I used and it works great (used late 2023/early 2024)
    #
    # *** gpt 3.5:
    # model="gpt-3.5-turbo-1106",
    # gpt-4 "turbo" and gpt-3.5-turbo are both fast, so use gpt-4 for accuracy (else 3.5 might need to be re-run/fixed which can cost more)

    return Service(
        name='openai',
        api_key=get_api_key('openai', 'ask'),
        base_url=None,
        model=model if model else 'gpt-4o',
    )


def use_lmstudio(model: str):

    # http://localhost:1234/v1/models
    return Service(
        name='lmstudio',
        api_key="whatever",
        base_url="http://localhost:1234/v1",
        model=model if model else '',
    )


def use_ollama(model: str):
    return Service(
        name='ollama',
        api_key="whatever",
        base_url="http://localhost:11434/v1",
        model=model if model else ''
    )


def get_api_key(service_name, account_name):

    if platform.system() == 'Linux':
        # https://pypi.org/project/keyrings.cryptfile/
        # pip install keyrings.cryptfile
        #
        # from keyrings.cryptfile.cryptfile import CryptFileKeyring
        # kr = CryptFileKeyring()
        # kr.set_password("groq","ask","foo")
        # kr.set_password("openai","ask","foo")
        # on linux, avoid prompt for password for cryptfile:
        kr = CryptFileKeyring()
        if getenv("KEYRING_CRYPTFILE_PASSWORD") is None:
            print("KEYRING_CRYPTFILE_PASSWORD env var not set")
            sys.exit(1)
        kr.keyring_key = getenv("KEYRING_CRYPTFILE_PASSWORD")
        keyring.set_keyring(kr)  # tell keyring to use kr (not other backends, and not try to setup keyring.cryptfile backend instance itself, b/c then it prompts for password)

    api_key = keyring.get_password(service_name, account_name)

    # windows => open Credential Manager => Windows Credentials tab => Generic Credentials section (add new)...  service_name => Internet/NetworkAddress, account_name => username
    # macos => open Keychain Access => kind=app password, (security add-generic-password IIRC)

    if api_key is None:
        print(f"No api_key found for account={account_name} in service={service_name}")
        sys.exit(1)
    return api_key


def generate_command(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        completion = client.chat.completions.create(
            model=use.model,
            messages=[{
                "role":
                "system",
                "content":
                "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
            }, {
                "role": "user",
                "content": f"{passed_context}"
            },
            # PRN can I improve phi3/mixtral by further telling it not to give me an explanataion, i.e.:
            # {
            #     "role": "system",
            #     "content": "The command line is:"
            # }],
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

    command = generate_command(stdin_context, use)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)


if __name__ == "__main__":
    main()
