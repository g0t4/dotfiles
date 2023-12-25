ealias pc="prlctl"
# list [-a,--all] [-f,--full] [-t,--template] [-L] [-o,--output <field>[,filed...]] [-s,--sort <field>]
# list -i,--info [-f,--full] [-j,--json] [<ID | NAME>]
ealias pcls="prlctl list --full --all"          # all VMs (regardless state) - and full so I get IPs
ealias pclsj="prlctl list --full --json --info" # super detailed json output # --all is irrelevant with --info

# completion is good enough for most of following... PRN add more:
# prlctl capture NAME -file foo.png
# prlctl enter|exec ID|name # requires parallels tools installed in guest
# status <ID | NAME>
# delete <ID | NAME>
# start <ID | NAME>
# resume <ID | NAME>
# pause <ID | NAME> [--acpi]
# suspend <ID | NAME>
# restart <ID | NAME>
# reset <ID | NAME>
# reset-uptime <ID | NAME>
# stop <ID | NAME> [--kill | --noforce | --acpi]
# register <PATH> [--uuid <UUID>] [--regenerate-src-uuid] [--force] [--delay-applying-restrictions]
# unregister <ID | NAME>
# create <NAME> {--ostemplate <name> | -o,--ostype <name | list> | -d,--distribution <name | list>}
#  [--dst <path>] [--changesid] [--no-hdd] [--lion-recovery] [--uuid <UUID>]

# docs:
#   index of help: https://download.parallels.com/desktop/v12/docs/en_US/Parallels%20Desktop%20Pro%20Edition%20Command-Line%20Reference/toc3922326.htm
#       TERRIBLE interface but it works
#   list # https://download.parallels.com/desktop/v12/docs/en_US/Parallels%20Desktop%20Pro%20Edition%20Command-Line%20Reference/23460.htm
#     - or from CLI `prlctl -help`
# https://docs.virtuozzo.com/virtuozzo_hybrid_server_7_command_line_reference/managing-virtual-machines/prlctlvm.html
