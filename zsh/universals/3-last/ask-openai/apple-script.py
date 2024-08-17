import sys
from os import getenv
from openai import OpenAI
import textwrap

from services import args_to_use, Service


def generate_command(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        system_message = textwrap.dedent("""
        You are an AppleScript expert.
        The user is working in Script Debugger or Script Editor.
        The user needs help completing statement(s) or something else about AppleScript.
        The user selected part of their script that they want to provide to you for help.
        If you see a comment prefixed by `-- help ...` without the backticks, that is the question/request and the rest is the relevant existing script code. Do whatever is asked in the comment in this case (i.e. modify the rest of the code).
        Respond with valid AppleScript statement(s).
        Your response will replace what they selected. So they can review and use it.
        Your responpse can include new lines if you have multiple lines.
        Comments are ok, only if absolutely necessary.
        No explanation. No markdown. No markdown with backticks ` nor ```.
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
            max_tokens=500,
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
    log_file = f"{getenv('HOME')}/.ask.apple-script.log"
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.name} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


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
