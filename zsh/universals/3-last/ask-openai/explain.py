from openai import OpenAI
import keyring
import sys

#! todo refactor with other impl later as needed (composition most likely)

def generate_command(context: str):

    # usages:
    #   question only:
    #     where is docker config
    #     how can I replace nginx's welcome page with "hello world"
    #   command only:
    #   question and command:

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
                "role": "system",
                "content": "You are a command line expert. I am sending you the contents of my current command line which may include a command and/or a question. Respond with a single, valid, complete command line. Append your explanation with a # sign as a comment. I intend to read your explanation and then execute the command too. Don't bloviate. No markdown blocks"
            }, {
                "role": "user",
                "content": f"{context}"
            }],
            max_tokens=200,
            n=1  # default
        )

        return completion.choices[0].message.content
    except Exception as e:
        print(f"{e}")
        return None


if __name__ == "__main__":

    context = sys.stdin.read()

    command = generate_command(context)
    if command is None:
        sys.exit(1)

    print(command)
