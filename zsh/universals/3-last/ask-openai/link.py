from openai import OpenAI
import keyring
import sys

#! todo refactor with other impl later as needed (composition most likely)

def generate_command(context: str):

    service_name = 'openai'
    account_name = 'ask'
    password = keyring.get_password(service_name, account_name)
    # windows => open Credential Manager => Windows Credentials tab => Generic Credentials section (add new)...  service_name => Internet/NetworkAddress, account_name => username
    # macos => open Keychain Access => kind=app password, (security add-generic-password IIRC)

    if password is None:
        print(f"No password found for {account_name} in {service_name}")
        sys.exit(1)

    client = OpenAI(api_key=password)
    try:

        completion = client.chat.completions.create(
            # models https://platform.openai.com/docs/models
            model="gpt-4-1106-preview",  # gpt-4 "turbo" (cheaper than gpt-4)
            # model="gpt-3.5-turbo-1106",
            # gpt-4 "turbo" and gpt-3.5-turbo are both fast, so use gpt-4 for accuracy (else 3.5 might need to be re-run/fixed which costs more)
            # ? gpt-3.5-turbo-instruct
            messages=[{
                "role":
                "system",
                "content":
                "You are a command line expert. Find out what I am struggling with, with the current command. Find me the first, best resource to help me with what I need help with. For example, if I have docker container run, respond with https://docs.docker.com/reference/cli/docker/container/run. I intend to open this link to read it. No explanation. No markdown blocks. Just ONE URL."
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
