import sys
from chat_non_stream import generate_non_streaming

# FYI this is a fallback for when you do not have iterm2 available.
#  i.e. on windows
#  this is integrated into each shell via a widget/keymap/bind in pwsh/zsh/fish
#  IOTW I really don't need this on my Mac
#  nor do I need this when remoting over SSH from iterm2 on my mac
#  only if I am say logged into a windows machine directly (or an arch desktop)
#   then I have to use ctrl+b too to activate this
#   this was my OG OG ask-openai plugin core

system_message = "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```"
max_tokens = 200

def main():

    stdin_context = sys.stdin.read()

    command = generate_non_streaming(stdin_context, system_message, max_tokens)
    if command is None:
        sys.exit(1)

    # response is piped to STDOUT => STDIN of SHELL => command line buffer (as if user typed it)
    print(command)

if __name__ == "__main__":
    main()
