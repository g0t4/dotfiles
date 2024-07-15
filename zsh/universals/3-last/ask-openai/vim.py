import sys
from os import getenv
from openai import OpenAI

from services import args_to_use, Service


def generate_command(passed_context: str, use: Service):

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a vim expert. The user (that you are talking to) has vim open in command mode."
                     + "They have typed part of a command that they need help with."
                     + "They might also have a question included at the end of the command, in a comment (after \" which denotes a comment in vim)"
                     + "Respond with a single, valid, complete vim command line. So it can be reviewed and executed."
                     + "No explanation. No markdown. No markdown with backticks ` nor ```"
                     # "If the user mentions another vim mode (i.e. insert mode or normal mode) then you can help them with that by returning text that they can read and not execute"
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            max_tokens=200,
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
    log_file = f"{getenv('HOME')}/.ask.single.log"
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
