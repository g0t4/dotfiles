import sys
from openai import OpenAI
import textwrap

from services import args_to_use, Service

def generate_command(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        system_message = textwrap.dedent("""
        You are a excel expert.
        The user is working in Excel.
        The user needs help completing a formula or something else to do with excel.
        Whatever they have typed into the Excel cell will be provided to you.
        They might also have a free-form question included.
        Respond with a single, valid excel formula. Their cell contents will be replaced with your response. So they can review and use it.
        No explanation. No markdown. No markdown with backticks ` nor ```.

        An example of a question could be `= sum up H4:H8` and a valid response would be `= SUM(H4:H8)`. Make sure to include the = sign if you are suggesting a formula.
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

    command = generate_command(stdin_context, use)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)

if __name__ == "__main__":
    main()
