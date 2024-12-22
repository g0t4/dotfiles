import sys
from openai import OpenAI
import textwrap

from services import args_to_use, Service

def generate_command(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        system_message = textwrap.dedent("""
        You are a chrome devtools expert.
        The user is working in the devtools Console in the Brave Beta Browser.
        The user needs help completing a javascript command.
        Whatever they have typed into the Console's command line will be provided to you.
        They might also have a free-form question included, i.e. in a comment (after //).
        Respond with a single, valid javascript command line. Their command line will be replaced with your response. So they can review and execute it.
        No explanation. No markdown. No markdown with backticks ` nor ```.

        An example of a command line could be `find the first div on the page` and a valid response would be `document.querySelector('div')`
        """)

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": system_message
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            max_tokens=200,
            n=1  # default
        )

        return completion.choices[0].message.content

    except Exception as e:
        print(f"{e}")
        return None

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
