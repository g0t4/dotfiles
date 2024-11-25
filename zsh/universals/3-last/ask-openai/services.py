import argparse
from os import getenv
import platform
import sys
from typing import Optional, NamedTuple

import keyring

class Service(NamedTuple):
    base_url: str
    model: str
    api_key: str
    name: str
    chat_completions_path: str|None

    def chat_url(self):
        if self.chat_completions_path is None:
            return f"{self.base_url}/chat/completions"
        else:
            return f"{self.base_url}/{self.chat_completions_path}"
    def __repr__(self):
        # i.e. printing (logging), DO NOT INCLUDE api_key
        return f"Service({self.name} model={self.model} chat_url={self.chat_url()})"

def use_groq(model: Optional[str] = None):

    return Service(
        name='groq',
        api_key=get_api_key('groq', 'ask'),
        base_url='https://api.groq.com/openai/v1',
        model=model if model else 'llama-3.1-70b-versatile',
        chat_completions_path= None,
        # groq https://console.groq.com/docs/models
        #   llama3-8b-8192, llama3-70b-8192, mixtral-8x7b-32768, gemma-7b-it, gemma2-9b-it
        #   llama-3.1-405b-reasoning, llama-3.1-70b-versatile, llama-3.1-8b-instant
        #   llama3-groq-70b-8192-tool-use-preview, llama3-groq-8b-8192-tool-use-preview
    )


def use_openai(model: Optional[str] = None):

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
        base_url="https://api.openai.com/v1",
        model=model if model else 'gpt-4o',
        chat_completions_path= None,
    )

def use_anthropic(model: Optional[str] = None):
    return Service(
        name='anthropic',
        api_key=get_api_key('anthropic', 'ask'),
        base_url="https://api.anthropic.com/v1",
        model=model if model else 'claude-3-5-sonnet-latest',
        chat_completions_path= "messages",
    )
    # https://docs.anthropic.com/en/docs/about-claude/models


def use_lmstudio(model: Optional[str] = None):

    # http://localhost:1234/v1/models
    return Service(
        name='lmstudio',
        api_key="whatever",
        base_url="http://localhost:1234/v1",
        model=model if model else '',
        chat_completions_path= None,
    )


def use_ollama(model: Optional[str] = None):
    return Service(
        name='ollama',
        api_key="whatever",
        base_url="http://localhost:11434/v1",
        model=model if model else '',
        chat_completions_path= None
    )

def use_deepseek(model: Optional[str] = None):
    # curl -L -X GET 'https://api.deepseek.com/models' \-H 'Accept: application/json' \-H 'Authorization: Bearer <TOKEN>' | jq
    # deepseek-chat
    # deepseek-coder
    # FYI w.r.t ``` ... deepseek-chat listens to request to not use ``` and ``` but deepseek-coder always returns ```... that actually makes sense for the coder...
    return Service(
        name='deepseek',
        # FYI `security add-generic-password -a ask -s deepseek -w`
        api_key=get_api_key('deepseek', 'ask'),
        base_url="https://api.deepseek.com",
        model=model if model else 'deepseek-chat',
        chat_completions_path= None,
    )

def get_api_key(service_name, account_name):

    if platform.system() == 'Linux':
        from keyrings.cryptfile.cryptfile import CryptFileKeyring
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
        keyring.set_keyring(
            kr)  # tell keyring to use kr (not other backends, and not try to setup keyring.cryptfile backend instance itself, b/c then it prompts for password)

    api_key = keyring.get_password(service_name, account_name)

    # windows => open Credential Manager => Windows Credentials tab => Generic Credentials section (add new)...  service_name => Internet/NetworkAddress, account_name => username
    # macos => open Keychain Access => kind=app password, (security add-generic-password IIRC)

    if api_key is None:
        print(f"No api_key found for account={account_name} in service={service_name}")
        sys.exit(1)
    return api_key


def args_to_use() -> Service:

    parser = argparse.ArgumentParser()
    parser.add_argument('--dump_config', action='store_true', default=False)
    parser.add_argument('--openai', action='store_true', default=False)
    parser.add_argument('--deepseek', action='store_true', default=False)
    parser.add_argument('--lmstudio', action='store_true', default=False)
    parser.add_argument('--groq', action='store_true', default=False)
    parser.add_argument('--ollama', action='store_true', default=False)
    parser.add_argument('--anthropic', action='store_true', default=False)

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
    elif args.deepseek:
        use = use_deepseek(args.model)
    elif args.anthropic:
        use = use_anthropic(args.model)
    else:
        use = use_openai(args.model)

    if args.dump_config:
        # print(args)
        print(use)
        exit(0)

    return use
