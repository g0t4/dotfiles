import argparse
import platform
import sys
from typing import Optional, NamedTuple

# subprocess.run check values:
IGNORE_FAILURE = False
RAISE_CalledProcessError_ON_FAILURE = True

class Service(NamedTuple):
    base_url: str
    model: str
    api_key: str
    name: str
    chat_completions_path: str | None
    max_tokens: int | None = None

    def chat_url(self):
        if self.chat_completions_path is None:
            return f"{self.base_url}/chat/completions"
        else:
            return f"{self.base_url}/{self.chat_completions_path}"

    def __repr__(self):
        # i.e. printing (logging), DO NOT INCLUDE api_key
        return f"Service({self.name} model={self.model} chat_url={self.chat_url()})"

    def log_safe_string(self):
        # make it abundantly clear this is safe to log, don't rely on __repr__ for logging when there's an api key that could slip out
        return f"Service({self.name} model={self.model} chat_url={self.chat_url()})"

def use_vllm(model: Optional[str] = None):
    return Service(
        name='vllm',
        api_key="none",
        base_url='http://ollama:8000/v1',
        model=model if model else "Qwen/Qwen2.5-Coder-7B-Instruct",
        chat_completions_path='chat/completions',
        # vllm https://github.com/vllm-project/vllm/blob/main/docs/api.md
        # https://github.com/vllm-project/vllm/blob/main/docs/api.md#chat-completions
    )

def use_build21(model: Optional[str] = None):
    return Service(
        name='build21',
        api_key="none",
        base_url='http://build21:8013/v1',
        model=model if model else 'llama-server-fixed',
        chat_completions_path=None,
        max_tokens=2048
    )

def use_inception(model: Optional[str] = None):
    return Service(
        name='inception',
        api_key=get_api_key('inception', 'ask'),
        base_url='https://api.inceptionlabs.ai/v1',
        model=model if model else 'mercury-coder-small',
        chat_completions_path=None,
        # https://platform.inceptionlabs.ai/dashboard/
    )

def use_groq(model: Optional[str] = None):

    return Service(
        name='groq',
        api_key=get_api_key('groq', 'ask'),
        base_url='https://api.groq.com/openai/v1',
        model=model if model else 'meta-llama/llama-4-scout-17b-16e-instruct',
        chat_completions_path=None,
        # groq https://console.groq.com/docs/models
    )


def use_gh_copilot(model: Optional[str] = None):
    # TODO reuse logic in my ask-openai.nvim plugin, basically take ~/.config/github-copilot/[apps|host].yml to get GH copilot API_KEY => get bearer token and go! cache the config so its not an extra step on every request, config has expiration field
    # TODO get base_url off of v2_token/config response
    raise Exception("not implemented yet")


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
        chat_completions_path=None,
    )


def use_anthropic(model: Optional[str] = None):
    return Service(
        name='anthropic',
        api_key=get_api_key('anthropic', 'ask'),
        base_url="https://api.anthropic.com/v1",
        model=model if model else 'claude-3-5-sonnet-latest',
        chat_completions_path="messages",
    )
    # https://docs.anthropic.com/en/docs/about-claude/models


def use_lmstudio(model: Optional[str] = None):

    # http://localhost:1234/v1/models
    return Service(
        name='lmstudio',
        api_key="whatever",
        base_url="http://localhost:1234/v1",
        model=model if model else '',
        chat_completions_path=None,
    )


def use_ollama(model: Optional[str] = None):
    # https://github.com/ollama/ollama/blob/main/docs/openai.md
    #   FYI yes it has openai compat api support, pay attention to failures for what might have gone wrong (i.e. 404 on invalid model)
    return Service(
        name='ollama',
        api_key="whatever",
        base_url="http://ollama:11434/v1",
        # TODO can blank be used and let it pick?
        model=model if model else 'llama3.2:3b',
        chat_completions_path=None)


def use_deepseek(model: Optional[str] = None):
    # curl -L -X GET 'https://api.deepseek.com/models' \-H 'Accept: application/json' \-H 'Authorization: Bearer <TOKEN>' | jq
    # deepseek-chat (DeepSeek-V3)
    # deepseek-reasoner (DeepSeek-R1 as of 2025-01-20)
    # https://api-docs.deepseek.com/quick_start/pricing
    return Service(
        name='deepseek',
        # FYI `security add-generic-password -a ask -s deepseek -w`
        api_key=get_api_key('deepseek', 'ask'),
        base_url="https://api.deepseek.com",
        model=model if model else 'deepseek-chat',
        chat_completions_path=None,
    )

def use_xai(model: Optional[str] = None):
    return Service(
        name='xai',
        api_key=get_api_key('xai', 'ask'),
        base_url="https://api.x.ai/v1",
        model=model if model else 'grok-3-beta',
        chat_completions_path=None,
    )

def get_api_key(service_name, account_name):

    if platform.system() == 'Darwin':
        import subprocess
        # using security command directly for speed (45ms vs 120ms to use library)
        cmd = ['security', 'find-generic-password', '-s', service_name, '-a', account_name, '-w']
        result = subprocess.run(cmd, text=True, capture_output=True, check=RAISE_CalledProcessError_ON_FAILURE)
        return result.stdout.strip()

    # only load for linux/macOS (no overhead for subsquent calls)
    import keyring

    if platform.system() == 'Linux':
        from keyrings.cryptfile.cryptfile import CryptFileKeyring
        from os import getenv
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

    # TODO why does this take __89ms__ to exec to the CLI for security cmd? can this be optimized? or is this a good reason to just leave a background service open locally so the overhead is irrelevant and then its a one time hit
    #   INSTEAD of perf hit EVERY time I use ask openai for any context
    #   FYI command call `security find-generic-password -a ask -s openai` takes 39ms in CLI
    api_key = keyring.get_password(service_name, account_name)

    # windows => open Credential Manager => Windows Credentials tab => Generic Credentials section (add new)...  service_name => Internet/NetworkAddress, account_name => username
    # macos => open Keychain Access => kind=app password, (security add-generic-password IIRC)

    if api_key is None:
        print(f"No api_key found for account={account_name} in service={service_name}")
        sys.exit(1)
    return api_key


def args_to_use() -> Service:

    parser = argparse.ArgumentParser()
    parser.add_argument('--openai', action='store_true', default=False)
    parser.add_argument('--deepseek', action='store_true', default=False)
    parser.add_argument('--lmstudio', action='store_true', default=False)
    parser.add_argument('--groq', action='store_true', default=False)
    parser.add_argument('--build21', action='store_true', default=False)
    parser.add_argument('--inception', action='store_true', default=False)
    parser.add_argument('--ollama', action='store_true', default=False)
    parser.add_argument('--anthropic', action='store_true', default=False)
    parser.add_argument('--gh-copilot', action='store_true', default=False)
    parser.add_argument('--xai', action='store_true', default=False)
    parser.add_argument('--vllm', action='store_true', default=False)

    # optional model name (for all services):
    parser.add_argument("model", type=str, const=None, nargs='?')
    #
    args = parser.parse_args()

    if args.groq:
        use = use_groq(args.model)
    elif args.lmstudio:
        use = use_lmstudio(args.model)
    elif args.ollama:
        use = use_ollama(args.model)
    elif args.deepseek:
        use = use_deepseek(args.model)
    elif args.vllm:
        use = use_vllm(args.model)
    elif args.anthropic:
        use = use_anthropic(args.model)
    elif args.gh_copilot:
        use = use_gh_copilot(args.model)
    elif args.build21:
        use = use_build21(args.model)
    elif args.inception:
        use = use_inception(args.model)
    elif args.xai:
        use = use_xai(args.model)
    elif args.openai:
        use = use_openai(args.model)
    else:
        raise Exception("invalid service: " + str(args))

    return use

import os

DEBUG = True

def log(msg):
    if not DEBUG:
        return
    print(msg)

## purpose of this is just to parse a shared config file to specify which service to use for completion tasks
## I could easily move this logic elsewhere but works fine in fish variable for now

def get_use() -> Service:

    # *** lookup backend => parse fish universal vars file (for ask_service)
    #   FYI vars file is unicode_escape'd (i.e. '\x2d\x2d' => '--')
    fish_vars_path = os.path.expanduser("~/.config/fish/fish_variables")
    if not os.path.exists(fish_vars_path):
        log("cannot read ask_service from fish universal variables file")
        use = use_build21(None)
    else:
        # read fish universal variables:
        # <2ms to read file
        with open(fish_vars_path, 'r', encoding="utf-8") as _file:
            lines = _file.readlines()
        # extract ask_service variable:
        ask_service_raw = next((line for line in lines if "ask_service" in line), None)
        if ask_service_raw is None:
            log("ask_service not found in fish universal variables file, using openai")
            use = use_openai(None)
        else:
            ask_service = ask_service_raw.encode('utf-8').decode('unicode_escape').strip()  # strip trailing \n
            ask_service_split = ask_service.split("\x1e")  # split on RS (record separator)
            model = ask_service_split[1] if len(ask_service_split) > 1 else None

            # PRN this parsing logic can be shared with single.py, after I re-hydrate the ask_service variable
            if "--ollama" in ask_service:
                use = use_ollama(model)
            elif "--groq" in ask_service:
                use = use_groq(model)
            elif "--deepseek" in ask_service:
                use = use_deepseek(model)
            elif "--vllm" in ask_service:
                use = use_vllm(model)
            elif "--lmstudio" in ask_service:
                use = use_lmstudio(model)
            elif "--anthropic" in ask_service:
                use = use_anthropic(model)
            elif "--gh-copilot" in ask_service:
                use = use_gh_copilot(model)
            elif "--build21" in ask_service:
                use = use_build21(model)
            elif "--inception" in ask_service:
                use = use_inception(model)
            elif "--xai" in ask_service:
                use = use_xai(model)
            elif "--openai" in ask_service:
                use = use_openai(model)
            else:
                raise Exception("invalid ask_service: " + str(ask_service))
    return use

