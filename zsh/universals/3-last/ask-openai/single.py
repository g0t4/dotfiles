from os import getenv
from openai import OpenAI
from keyrings.cryptfile.cryptfile import CryptFileKeyring
import keyring
import sys
import platform


def generate_command(context: str):

    use_groq = True

    if platform.system() == 'Linux':
        # https://pypi.org/project/keyrings.cryptfile/
        # pip install keyrings.cryptfile
        #
        # from keyrings.cryptfile.cryptfile import CryptFileKeyring
        # CryptFileKeyring().set_password("groq","ask","foo")

        # on linux, avoid prompt for password for cryptfile:
        kr = CryptFileKeyring()
        kr.keyring_key = getenv("KEYRING_CRYPTFILE_PASSWORD")

    service_name = 'groq' if use_groq else 'openai'
    account_name = 'ask'
    password = keyring.get_password(service_name, account_name)

    # windows => open Credential Manager => Windows Credentials tab => Generic Credentials section (add new)...  service_name => Internet/NetworkAddress, account_name => username
    # macos => open Keychain Access => kind=app password, (security add-generic-password IIRC)

    if password is None:
        print(f"No password found for {account_name} in {service_name}")
        sys.exit(1)

    # grok base_url https://console.groq.com/docs/openai
    base_url = "https://api.groq.com/openai/v1" if use_groq else None
    client = OpenAI(api_key=password, base_url=base_url)

    try:

        if use_groq:
            # groq https://console.groq.com/docs/models
            #   llama3-8b-8192, llama3-70b-8192, llama2-70b-4096, mixtral-8x7b-32768, gemma-7b-it
            model = "llama3-70b-8192"
            # wow llama3-* are fast... not sure yet about quality, time will tell
            # print("Using Groq")
        else:
            # openai https://platform.openai.com/docs/models
            #
            # gpt4 models: https://platform.openai.com/docs/models/gpt-4-turbo-and-gpt-4
            # *** gpt4 turbo (adds vision capabilities): # does this add anything else besides vision to the turbo preview?
            # model = "gpt-4-turbo" # currently => "gpt-4-turbo-2024-04-09" # TODO test this vs preview for my use case
            # model = "gpt-4-turbo-2024-04-09" # thru Dec 2023
            # *** gpt4 turbo previews:
            model = "gpt-4-turbo-preview"  # currently => "gpt-4-0125-preview"
            # model = "gpt-4-0125-preview" # thru Dec 2023 - aka gpt4 turbo
            # model = "gpt-4-1106-preview", # thru Apr 2023 - aka gpt4 turbo # ! this model is the first I used and it works great (used late 2023/early 2024)
            #
            # *** gpt 3.5:
            # model="gpt-3.5-turbo-1106",
            # gpt-4 "turbo" and gpt-3.5-turbo are both fast, so use gpt-4 for accuracy (else 3.5 might need to be re-run/fixed which can cost more)

        completion = client.chat.completions.create(
            model=model,
            messages=[{
                "role": "system",
                "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown blocks"
            }, {
                "role": "user",
                "content": f"{context}"
            }],
            max_tokens=80,
            n=1  # default
        )

        return completion.choices[0].message.content
    except Exception as e:
        print(f"{e}")
        return None


if __name__ == "__main__":

    context = sys.stdin.read()
    # empty context usually generates echo hello :) so allow it

    if "question: dump\n" in context:
        # dump context to troubleshoot
        print(context)
        sys.exit(2)

    command = generate_command(context)
    if command is None:
        sys.exit(1)

    print(command)
