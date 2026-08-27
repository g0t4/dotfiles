# this script makes the equivalent of `fish -C` possible
#  by running a passed command so that when it exits, the xonsh shell remains open (interactive)
#   an interactive `init command`

# if 'XONSH_WES_INTERACTIVE_INIT_COMMAND' in ${...}:
#     echo $XONSH_WES_INTERACTIVE_INIT_COMMAND

if cmd := ${...}.pop('XONSH_WES_INTERACTIVE_INIT_COMMAND', None):
    execx(cmd)
