import sys
from services import args_to_use
from suggest import get_openai_suggestion

# TODO there seems to be some lag due to keyboard maestro (probabaly in calling fish => python overhead)
#    I found a few seettings for delays and set them to 0 and its sliightly helped but 200ms still fels like 1+ seconds (vs test at CLI where I run the test fish script that calls same thing)
#   FYI run test fish script like KM would run is 200ms overhead w/o import openai and generate_command... so smth else might be slowing down KM... though it is hard to say my perception of time is ridiculous :) ... half a second likely feels like 2 to me

system_message = """
You are a chrome devtools expert.
The user is working in the devtools Console in the Brave Beta Browser.
The user needs help completing a javascript command.
Whatever they have typed into the Console's command line will be provided to you.
They might also have a free-form question included, i.e. in a comment (after //).
Respond with a single, valid javascript command line. Their command line will be replaced with your response. So they can review and execute it.
No explanation. No markdown. No markdown with backticks ` nor ```.

An example of a command line could be `find the first div on the page` and a valid response would be `document.querySelector('div')`
"""
max_tokens = 200


def main():

    use = args_to_use()

    stdin_context = sys.stdin.read()

    command = get_openai_suggestion(stdin_context, system_message, use, max_tokens)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)


if __name__ == "__main__":
    main()
