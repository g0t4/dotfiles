import sys
from services import args_to_use
from suggest import generate

system_message = "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
max_tokens = 200


def main():

    use = args_to_use()

    stdin_context = sys.stdin.read()

    command = generate(stdin_context, system_message, use, max_tokens)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)


if __name__ == "__main__":
    main()
