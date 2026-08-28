# this script makes the equivalent of `fish -C` possible
#  by running a passed command so that when it exits, the xonsh shell remains open (interactive)
#   an interactive `init command`
# call this with /usr/bin/env "XONSH_WES_INTERACTIVE_INIT_COMMAND=your_command" /path/to/xonsh

import subprocess, shlex

if cmd := ${...}.pop('XONSH_WES_INTERACTIVE_INIT_COMMAND', None):
    # print("cmd", cmd)
    args = shlex.split(cmd)
    # print("args after shlex", args)
    subprocess.run(args)
    # subprocess.run([ "ssh", "arch1"])
