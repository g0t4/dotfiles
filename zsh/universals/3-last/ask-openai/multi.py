from openai import OpenAI
import keyring
import sys


def generate_command(num_suggestions, context: str):

    service_name = 'openai'
    account_name = 'ask'
    password = keyring.get_password(service_name, account_name)

    if password is None:
        print(f"No password found for {account_name} in {service_name}")
        sys.exit(1)

    client = OpenAI(api_key=password)
    try:

        completion = client.chat.completions.create(
            model="gpt-4-1106-preview",
            # model="gpt-3.5-turbo-1106",
            # ? gpt-3.5-turbo-instruct
            messages=[{
                "role": "system",
                "content": "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown blocks. Only quote if necessary and prefer ' over \""
                # blurb about ' \ " was simple attempt to try to quash variation from just '\" args but didn't really work :), PRN improve
            }, {
                "role": "user",
                "content": f"{context}"
            }],
            max_tokens=200,
            n=num_suggestions,
            # GPT 4 tends to produce deterministic responses w/ little variation when it comes to suggesting commands so honestly that obviates the need for multiple suggestsions! whereas v3.5 was more creative but then again if what GPT 4 comes up with works then it may cost less b/c not generating as many tokens!
            # - so, just use GPT4 w/ 1 suggestion?
            # - and, leave helps/multi for one-off scenarios where I want multiple suggestions
        )

        for choice in completion.choices:
            print(choice.message.content)
    except Exception as e:
        print(f"{e}")
        sys.exit(1)


if __name__ == "__main__":

    question = " ".join(sys.argv[1:])
    num_suggestions = 3
    # PRN set # from first arg? (or default to 3)

    # empty context usually generates echo hello :) so allow it

    if question == "dump":
        # dump context to troubleshoot
        print(question)
        sys.exit(2)

    generate_command(num_suggestions, question)
