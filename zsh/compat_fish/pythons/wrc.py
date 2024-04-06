# main method, take variable list of args and invoke them as a sub process (shell command)

import argparse
import re
import subprocess
import sys


def args_regex(args: list, regex) -> bool:
    args_string = " ".join(args)
    return regex.search(args_string)


def decide_kubectl(args: list) -> list:
    if not "kubectl" in args:
        return None
    # PRN use some sort of arg parser that isn't so strict so I don't have to bother with the regexes
    #   or just roll my own on top of some basic arg parsing like I have here with reused regexes below
    if args_regex(args, re.compile(r"(-o|--output)(=|\s+)yaml")):
        return ["bat", "--language", "yaml"]
    if args_regex(args, re.compile(r"(-o|--output)(=|\s+)json")):
        return ["jq", "."]

    # kubectl get => grc
    if args_regex(args, re.compile(r"get")):
        return ["grcat", "conf.kubectl"]

    return None


def decide_formatter(args: list) -> list:

    # DOWN THE ROAD
    #   - make transparent so wrc always used (i.e. asciinema recording style where I open a subshell with wrc running... or wrc becomes my login shell and uses fish behind the scenes...)
    #   - once transparent, I will be able to take in pipelines, not just single commands, and so I will want more advanced decision logic that needs to consider the entire pipeline, not what is just one command (b/c wrc foo | bar ... would only see foo command, b/c its output is passed to bar)

    # if command is formatter then no need to do anything, not likely to do this (wrc bat) but if I make this wrc transparent (goal) then it will happen b/c I won't explicitly decide when to prepend it
    if args[0] in ["bat", "grc", "jq"]:
        return None

    # right now this is basically a combo of grc and bat/jq/etc as grc cannot handle file formats so well (uses regexes to color output) ... also this adds new mechanisms to decide if grcat should be used beyond the regexes defined in grc's config files... (i.e. kubectl get always maps to grcat conf.kubectl if no other formatter is detected prior like bat for yaml, jq for json)

    # idea
    # alias kubectl "grc kubectl" # works great but of course grc doesn't support using bat/jq (i.e. tab complete works)
    #   alias kubectl "wrc kubectl" # will and does kinda work but tab completion is at times broken... I would need to make the alias more complex to not ever format in the case of tab completion requests.. or smth ..

    # todo add unit tests of formatter decisions
    formatter_args = decide_kubectl(args)
    if formatter_args is not None:
        return formatter_args
    # TODO ansible next => see my zsh wrapper script (shudder) that has logic already for some of this
    # TODO also look at that python script that I used to modify the command line based on contents to insert grc/bat/jq/etc

    # default to grc?
    return None


def wrc(args: list):
    if len(args) == 0:
        print("No arguments provided")
        sys.exit(1)

    formatter_args = decide_formatter(args)
    if formatter_args is None:
        # no formatter found, just run single command for now
        # TODO add dynamic detection of formatter based on initial line(s) of output or another heuristic
        command = subprocess.Popen(args)
        command.communicate()
        return

    # formatter detected:
    command = subprocess.Popen(args, stdout=subprocess.PIPE)
    bat_format = subprocess.Popen(formatter_args, stdin=command.stdout)

    # allow command process (process 1) to receive a SIGPIPE if bat_format (process 2) exits
    command.stdout.close()

    # Wait for the bat_format (process 2) to finish
    bat_format.communicate()


if __name__ == "__main__":
    wrc(sys.argv[1:])
