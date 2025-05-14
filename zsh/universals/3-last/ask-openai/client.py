import os
from openai import AsyncOpenAI
from services import *

DEBUG = True

def log(msg):
    if not DEBUG:
        return
    print(msg)

## purpose of this is just to parse a shared config file to specify which service to use for completion tasks
## I could easily move this logic elsewhere but works fine in fish variable for now

def get_ask_client() -> tuple[Service, AsyncOpenAI]:

    # TODO profile this, takes 50-60ms to run (read file and build client) and see if there are ways to optimize... 50ms is borderline too slow for a responsive Ux for asking for help... seems way too high too to read a file...
    #   PRN store variable in a dedicated file (not need to parse other lines?)
    #   PRN or if its slow to build the AsyncOpenAI client then switch to maybe httpx client?

    # *** lookup backend => parse fish universal vars file (for ask_service)
    #   FYI vars file is unicode_escape'd (i.e. '\x2d\x2d' => '--')
    fish_vars_path = os.path.expanduser("~/.config/fish/fish_variables")
    if not os.path.exists(fish_vars_path):
        log("cannot read ask_service from fish universal variables file")
        use = use_openai(None)
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
            elif "--inception" in ask_service:
                use = use_inception(model)
            elif "--xai" in ask_service:
                use = use_xai(model)
            elif "--openai" in ask_service:
                use = use_openai(model)
            else:
                raise Exception("invalid ask_service: " + str(ask_service))

    # 20ms to create client... YUCK, almost no time to read file above (<2ms)
    client = AsyncOpenAI(api_key=use.api_key, base_url=use.base_url, timeout=15)
    # timeout (seconds), don't want shell locked up for the default (seems like 60s?)

    return use, client

