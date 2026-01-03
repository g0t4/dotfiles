if not status is-interactive
    # *** this file is ALL interactive only modifications (especially command/func overrides, but also abbrs are useless to non-interactive)
    return
end

# modify delay to consider if esc key a seq or standalone
set fish_escape_delay_ms 200 # 30ms is default and way too fast (ie esc+k is almost impossible to trigger)

# PRN add a binding to clear screen + reset status of last run command
#    OR modify prompt (type fish_prompt) as it already distinguishes (with bold) if status was carried over from previous command so perhaps I could find a way to hijack that ?
#    OR hide status in the prompt (perhaps like zsh I could show non-zero exit code on last line before new prompt?)

### FISH HELP ###
set __fish_help_dir "" # overwrite fish help dir thus forcing the use of https://fishshell.com instead of local files (which I prefer b/c I have highlighting of fishshell.com pages) # ... try it with: `help help` => opens https://fishshell.com/docs/3.6/interactive.html#help
# see `type help` to find the part of the help command that decides what to open

### BINDINGS ###
# some of these might be a result of setting up iTerm2 to use xterm default keymapping (in profile), might need to adjust if key map is subsequently changed
# bind_both_modes_default_and_insert shift-delete kill-word # shift+del to kill forward a word (otherwise its esc+d only), I have a habit of using this (not sure why, probably an old keymapping in zsh or?)
#  dont wanna clobber new shift-delete in autosuggests... and I don't think I used shift-delete often for delete forward anyways
function on_change_show_verbose_prompt --on-variable show_verbose_prompt
    commandline --function repaint
end
function toggle_show_verbose_prompt
    if not set --query show_verbose_prompt
        set --universal show_verbose_prompt yes
    else
        set --universal --erase show_verbose_prompt
    end
    # commandline --function repaint
end
bind_both_modes_default_and_insert f4 toggle_show_verbose_prompt

if command -q launchctl
    abbr lcl 'launchctl list'
    abbr lcp 'launchctl print system'
    abbr lcpu 'launchctl print user/$(id -u)'
    abbr lcpg 'launchctl print gui/$(id -u)'
    abbr lcds 'launchctl disable system/'
    abbr lcdu 'launchctl disable user/$(id -u)'
    abbr lcdg 'launchctl disable gui/$(id -u)'
    # PRN lce (enable)
    abbr lcstart 'launchctl start TODO'
    abbr lcstop 'launchctl stop TODO'
    abbr lcrm 'launchctl remove TODO'
    #
    abbr lcexamine 'launchctl examine TODO'
    # blame
    # debug
    # attach # cool! (first set debug, then restart, then attach)
    #

    # TODO flesh out later
end

# *** systemctl (if avail)
if command -q systemctl

    # * sc == prefix for system services
    abbr sc 'sudo systemctl'
    # * scu == prefix for user services
    abbr scu 'systemctl --user'
    abbr scudr 'systemctl --user daemon-reload'
    abbr scdr "sudo systemctl daemon-reload"

    abbr scm 'man systemd.index' # great entrypoint to systemd man pages

    abbr scs 'sudo systemctl status'
    abbr scus 'systemctl --user status'
    abbr scstop 'sudo systemctl stop'
    abbr scustop 'systemctl --user stop'
    abbr scstart 'sudo systemctl start'
    abbr scustart 'systemctl --user start'
    abbr screstart 'sudo systemctl restart'
    abbr scurestart 'systemctl --user restart'
    abbr scenable 'sudo systemctl enable'
    abbr scuenable 'systemctl --user enable'
    abbr scdisable 'sudo systemctl disable'
    abbr scudisable 'systemctl --user disable'
    abbr sck 'sudo systemctl kill'
    abbr scukill 'systemctl --user kill'

    abbr sccat 'sudo systemctl cat'
    abbr scucat 'systemctl --user cat'
    abbr scedit 'sudo systemctl edit'
    abbr scuedit 'systemctl --user edit'
    abbr screvert 'sudo systemctl revert'
    abbr scurevert 'systemctl --user revert'
    abbr scshow 'sudo systemctl show'
    abbr scushow 'systemctl --user show'

    abbr scls 'sudo systemctl list-units'
    abbr sculs 'systemctl --user list-units'
    abbr sclsf 'sudo systemctl list-unit-files'
    abbr sculsf 'systemctl --user list-unit-files'
    abbr sclss 'sudo systemctl list-sockets'
    abbr sculss 'systemctl --user list-sockets'
    abbr sclsd 'sudo systemctl list-dependencies'
    abbr sculsd 'systemctl --user list-dependencies'

    # * jc == prefix for system services
    abbr jc 'sudo journalctl --unit'
    # * jcu == prefix for user services
    abbr jcu 'journalctl --user --unit'

    abbr jcb 'sudo journalctl --boot --unit' # current boot
    abbr jcub 'journalctl --user --boot --unit' # current boot
    abbr jcb1 'sudo journalctl --boot=-1 --unit' # previous boot
    abbr jcub1 'journalctl --user --boot=-1 --unit' # previous boot
    abbr jcboots 'sudo journalctl --list-boots'

    abbr jcs 'sudo journalctl --since "1min ago" --unit'
    abbr jcus 'journactl --user --since "1min ago" --unit'
    abbr jck 'sudo journalctl -k' # kernel/dmesg
    abbr jcuk 'journalctl --user -k'

    abbr jcf 'sudo journalctl --follow --unit'
    abbr jcuf 'journalctl --user --follow --unit'
    abbr jcfa 'sudo journalctl --follow --no-tail --unit' # all lines + follow
    abbr jcufa 'journalctl --user --follow --no-tail --unit' # all lines + follow

    # AFAICT I don't need user equivalentsof rotate/vacuum
    # WIP - figure out what I want for cleanup, when testing I often wanna just clear all logs and try some activity to simplify looking at journalctl history, hence jcnuke
    abbr jcnuke 'sudo journalctl --rotate --vacuum-time=1s' # ~effectively rotate (archive all active journal files) then nuke (all archived journal files)
    abbr jcr 'sudo journalctl --rotate' # rotate (archive) all active journal files (new journal files going forward)
    abbr jcvs 'sudo journalctl --vacuum-size=100M' # vacuum logs to keep total size under 100M
    #
    abbr jcdu 'sudo journalctl --disk-usage' # total disk usage
    abbr jcud 'journalctl --user --disk-usage'
end

# *** containerd
if command -q ctr

    abbr ctr 'sudo ctr'
    abbr ctrn 'sudo ctr namespaces ls'

    # containers:
    abbr ctrc 'sudo ctr container ls'
    abbr ctrci 'sudo ctr container info'
    abbr ctrcrm 'sudo ctr container rm'

    # images:
    abbr ctri 'sudo ctr image ls'
    abbr ctripull --set-cursor 'sudo ctr image pull docker.io/library/%'
    abbr ctrirm --set-cursor 'sudo ctr image rm docker.io/library/%'

    # tasks:
    abbr ctrtls 'sudo ctr task ls'
    abbr ctrtps 'sudo ctr task ps' # by CID
    abbr ctrta 'sudo ctr task attach'
    abbr ctrtrm 'sudo ctr task rm'
    abbr ctrtk 'sudo ctr task kill --all'
    abbr ctrtks 'sudo ctr task kill --all --signal=SIGKILL'
    abbr ctrtpause 'sudo ctr task pause'
    abbr ctrtresume 'sudo ctr task resume'
    abbr ctrtstart 'sudo ctr task start' # created container that is not running
    abbr ctrtexec 'sudo ctr task exec --tty --exec-id 100 '

    # run:
    abbr ctrr 'sudo ctr run -t --rm'
    # demo examples:
    abbr ctrrnd 'sudo ctr run -d docker.io/library/nginx:latest web' # w/o host networking
    abbr ctrrn 'sudo ctr run -t --rm --net-host docker.io/library/nginx:latest web' # w/ host networking

    # content
    # leases
    # snapshots

    # *** containerd
    #  a few useful commands, just qualify them w.r.t. containerd full command name, rare but useful
    abbr containerdc "containerd config dump | bat -l toml"
    abbr containerdcdefault "containerd config default | bat -l toml"
    # PRN try new abbr --command option instead:   containerd c<TAB>  ???

end

if command -q k3s

    abbr k3s 'sudo k3s' # most helpful with say `sudo k3s ctr ...` b/c k3s containerd sock is owned by root:root
    # `sudo k3s kubectl ...` might be useful too if lowly user doesn't have access to k3s kubeconfig, but it is easy enough to use kubectl directly

    # PRN what about some sort of env/context selection for ctr socket? i.e:
    #    export CONTAINERD_ADDRESS=unix:///run/k3s/containerd/containerd.sock
    #    sudo -E ctr ... # shows k3s containerd instance resources
    #
    #    vs default address: /run/containerd/containerd.sock

    function _k3s_autocomplete
        # *** DUCK TAPE and bailing twine ***
        # set -l cur (commandline -ct) # current token (up to cursor position) => empty if cursor is preceeded by space
        set -l prev (commandline -cp) # current process (back to the last pipe or start of current command), i.e.:
        #    echo foo | k3s ser<CURSOR> => commmandline -cp => 'k3s ser'
        # echo "prev: $prev"
        # return
        # TODO would be an improvement to break this out into separate completion functions and defer to completions of prominent subcommands externally: ctr, kubectl, etc

        # FYI k3s uses urfave/cli
        # - : https://pkg.go.dev/github.com/urfave/cli@v1.22.14#example-App.Run-BashComplete
        # - has FISH completion support, look into a PR to k3s:
        #   - https://pkg.go.dev/github.com/urfave/cli@v1.22.14#App.ToFishCompletion
        #   - https://github.com/urfave/cli/blob/v1.22.14/fish.go#L13

        # --generate-bash-completion is a k3s feature that generates bash completion for k3s commands (not all though AFAICT, i.e. not k3s ctr and that makes sense cuz ctr completions would be independent of k3s)
        #   `k3s completion bash` =>
        #       bash completion scripts (ported to this fish completion func)
        #       differentiates on -* vs (not start w/ -) == options vs subcommands => but, same completions regardless if include or exclude current token in my testing so I am not differentiating here:
        set -l opts (eval $prev --generate-bash-completion)
        for opt in $opts
            echo $opt
        end
    end

    # Register the function for autocompletion with k3s, '' => defer func invoke until completion is requested
    # -f => no file completion... TODO is there a situation in which I would want that? definitely not for top level k3s completions
    complete -c k3s -a '(_k3s_autocomplete)' -f

    # PRN if this doesn't work out well for fish completions, I could break out sub commands and customize completions for each
end

if command -q k3d
    # k3d (idea: use k3d so I can avoid a space and then also avoid subcommand/subsubcommand)
    #   primary subcommand is cluster... so just let sub-subs there be top level in the alias/abbr namespace
    # cluster
    abbr k3dls 'k3d cluster list'
    abbr k3dcreate 'k3d cluster create'
    abbr k3ddelete 'k3d cluster delete'
    abbr k3dedit 'k3d cluster edit --port-add'
    abbr k3dstart 'k3d cluster start'
    abbr k3dstop 'k3d cluster stop'
    # image
    abbr k3di 'k3d image import' # from docker images
    # node
    abbr k3dn 'k3d node list'
    # registry
    abbr k3dr 'k3d registry list'
end

if command -q kubectl
    alias kubectl "grc kubectl" # ! EVALUATING if I like this, would be sufficient for short term most likely
    export KUBECTL_EXTERNAL_DIFF="icdiff -r" # use icdiff for kubectl diff (slick!)... FYI $1 and $2 are directories to compare (hence the -r)

    abbr --command kubectl --position=anywhere -- oy '-o yaml' # I used to pipe to yq... but I wrapped 'grc kubectl' to be 'kubectl' and don't need yq now
    abbr --command kubectl --position=anywhere -- ow '-o wide' # I don't believe this will cause collisions b/c it is not a word I expect to use in other contexts, lets see

    # *** get
    # ! TODO fix completions with grc command and put back grc on front?
    abbr kg 'kubectl get' # if I don't have the type already then I will want to tab complete it so don't include grc
    abbr kgf 'kubectl get -f' # status of resources defined in yml file # file completion will work w/ grc so leave it?
    #
    abbr kgns 'kubectl get namespaces'
    # TODO redo get aliases to use abbreviations where applicable (ie n=>ns)
    #
    function kgdump
        # usages:
        #    kgdump [-t regex] [namespace]
        #    kgdump -t ingress
        #    kgdump -t helm
        #    kgdump kube-system
        #    kgdump -t ingress kube-system
        argparse --name kgdump 't/type=' -- $argv
        # TLDR: pattern search all resources by namespace/type/name (or all if no args) => this is the long term goal, todo impl
        #   PRN add 'n/name=' flag to filter resources by name too (wait until I want this)
        #   PRN modify namespace arg to be a flag too? to avoid confusion?  AND make it regex/pattern also
        set filter -A # all namespaces (default)

        if test (count $argv) -gt 0
            # filter on namespace, keep as list to pass as args below
            set filter -n $argv
        else
            # only dump non-namespaced if no namespace requested
            log_ --red "NOT NAMESPACED:"
            set types (kubectl api-resources --verbs=list --namespaced=false -o name)
            if set -q _flag_type
                set types (string match -r ".*$_flag_type.*" -- $types)
            end
            if test (count $types) -eq 0
                log_ --brwhite --bold "  NO matching types found"
            else
                set comma_list (string join , $types)
                set what kubectl get --show-kind --ignore-not-found $comma_list
                log_ --black "  $what"
                eval $what
            end
        end

        log_blankline
        log_ --red "NAMESPACED( $filter ):"
        set types (kubectl api-resources --verbs=list --namespaced=true -o name)
        if set -q _flag_type
            set types (string match -r ".*$_flag_type.*" -- $types)
        end
        if test (count $types) -eq 0
            log_ --brwhite --bold "  NO matching types found"
        else
            set comma_list (string join , $types)
            set what kubectl get --show-kind --ignore-not-found $comma_list $filter
            log_ --black "  $what"
            eval $what
        end

        # FYI can also use smth like:
        #   kubectl get $(kubectl api-resources --verbs=list --namespaced -o name | paste -sd, -) --all-namespaces
    end
    # kgdump completions
    complete -c kgdump -s t -l type -d 'filter by type (regex/pattern)'
    # ? -n/--name
    complete -c kgdump -a '(kubectl get namespace -o custom-columns=:metadata.name)' --no-files
    #
    #
    abbr kga 'kubectl get all'
    abbr kgaa 'kubectl get all -A' # -A/--all-namespaces
    abbr kgas 'kubectl get all --show-labels'
    abbr kgb 'kubectl get -A backups,snapshots' # longhorn.io
    #
    abbr kgp 'kubectl get pods' # alias: po (gonna go with p only for now)
    abbr kgpa 'kubectl get pods -A'
    abbr kgpaw 'kubectl get pods -A --watch'
    #
    # PRN prune list or add other resource types:
    abbr kgcm 'kubectl get configmaps' # alias: cm
    abbr kgcr 'kubectl get clusterroles'
    abbr kgcrb 'kubectl get clusterrolebindings -o wide' # wide shows subject (user/group/sa) too which is critical IMO
    abbr kgcrd 'kubectl get customresourcedefinitions' # alias: crd,crds
    abbr kgds 'kubectl get daemonsets' # alias: ds
    abbr kgep 'kubectl get endpoints' # alias: ep
    abbr kgepA 'kubectl get endpoints -A' # all endpoints
    abbr kgend 'kubectl get svc,endpoints,endpointslices' # PRN do I like this combo? mostly as a reminder that this is a set I like to use... can find with ctrl+S in tab completion
    abbr kgev 'kubectl get events' # alias: ev
    abbr kging 'kubectl get ingresses' # alias: ing
    abbr kgj 'kubectl get -A jobs,cronjobs'
    abbr kgno 'kubectl get nodes' # alias: no
    abbr kgpv 'kubectl get persistentvolumes' # alias: pv
    abbr kgpvc 'kubectl get persistentvolumeclaims' # alias: pvc
    #
    abbr --set-cursor kgr 'kubectl get --raw /% | yq -P'
    # abbr 'kgr/' 'kubectl get --raw / | yq -P' # todo I can use kgr/ if I want kgr for smth else
    abbr kgr/a 'kubectl get --raw /apis'
    abbr kgr/h 'kubectl get --raw /healthz'
    abbr kgr/l 'kubectl get --raw /livez'
    abbr kgr/m 'kubectl get --raw /metrics'
    abbr kgr/o 'kubectl get --raw /openapi'
    # /openid
    abbr kgr/r 'kubectl get --raw /readyz'
    abbr kgr/v 'kubectl get --raw /version'
    #
    abbr kgrb 'kubectl get rolebindings -o wide' # wide shows role and subject (user/group/sa) so I absolutely want this by default
    abbr kgro 'kubectl get roles'
    abbr kgrs 'kubectl get replicasets' # alias: rs
    abbr kgs 'kubectl get svc'
    abbr kgsa 'kubectl get serviceaccounts' # alias: sa
    abbr kgsc 'kubectl get storageclasses' # alias: sc
    abbr kgsecrets 'kubectl get secrets' # no builtin alias, so use full name
    abbr kgsts 'kubectl get statefulsets' # alias: sts
    abbr kgrev 'kubectl get pods,sts,controllerrevisions' # crev is not a valid short name for controllerrevisions, but it fits nicely into my abbreviation namespaces... # PRN only return controllerrevisions (or also sts+pods?)
    abbr kgsvc 'kubectl get services' # alias: svc
    # *** volumes/storage ***
    abbr kgv --function _abbr_kgv
    function _abbr_kgv
        # FYI STDOUT is used to replace the "kgv" abbreviation
        if kubectl get crds/volumes.longhorn.io 2>/dev/null >/dev/null
            # if longhorn volumes CRD then include volumes (first in list)
            echo kubectl get -A volumes,pv,pvc,sc
        else
            echo kubectl get -A pv,pvc,sc
        end
        # PRN can include other CRDs here as needed! neat way to do this!
    end
    # *** END GET related:

    # apply
    abbr kaf 'kubectl apply -f' # create or modify
    abbr kad 'kubectl apply --dry-run=client -f' # dry-run
    abbr kak 'kubectl apply -k .' # assumes kustomization dir is current dir (i.e. kustomization.yaml)
    abbr kk 'kubectl kustomize' # (sort next to kak b/c they are companions) - preview rendered yaml (≈ dry-run)
    # api-versions/resources
    abbr kar 'kubectl api-resources'
    abbr kara 'kubectl api-resources --api-group'
    abbr karn 'kubectl api-resources --namespaced=true'
    abbr karg 'kubectl api-resources --namespaced=false' # (g)lobal
    abbr kav 'kubectl api-versions'
    # attach
    abbr kattach 'kubectl attach -it' # ~ docker container attach
    # create
    abbr kc 'kubectl create'
    abbr kcf 'kubectl create -f' # from file
    # cp
    abbr kcp 'kubectl cp' # ~ docker container cp
    # delete
    abbr kdel 'kubectl delete'
    abbr kdeli 'kubectl delete --interactive' # mostly a reminder to consider showing in demos
    abbr kdeld 'kubectl delete --dry-run' # mostly a reminder to consider showing in demos
    abbr kdelf 'kubectl delete -f'
    abbr kdelp 'kubectl delete pod' # alias: delp
    # diff
    abbr kdi 'kubectl diff' # diff current (status) vs desired state (spec)
    abbr kdif 'kubectl diff -f'
    # desc
    # ! grc is busting tab completion with kubectl... try end w/ bat instead ... don't mass apply to all other commands, see how I feel about it here first... this is where I want my shell to apply this for me (I can re-enable that part of my ENTER binding!)
    abbr kd 'kubectl describe' # ~ docker inspect
    abbr kdf 'kubectl describe -f'
    # edit
    abbr kedit 'kubectl edit'
    # exec
    abbr ke 'kubectl exec -it' # ~ docker container exec
    function kdd --description "kwe <TAB> <ENTER> and you're in, named (dd like docker debug)"
        kubectl wait --for=condition=Ready $argv # that way if its not running yet I don't have to run exec later
        kubectl exec -it $argv -- bash
        if test $status -ne 0
            log_ --blue "bash failed, trying sh"
            kubectl exec -it $argv -- sh
        end
        # TODO how do I wanna handle fallbacks and finding the shell to use...
        # PRN add tools mount point? and use it to provide shell (preconfigured too)
        #    think `docker debug` ... probably use nix-shell too
        #    also can have shell history!
    end
    complete -c kdd -a '(kubectl get pod -o name)' --no-files
    # kubectl get pods -o custom-columns=:metadata.name

    # events (grc is often helpful with event history - i.e. paths highlighted, statuses marked red/green/etc which helps the lenghty messages be readable)
    abbr kev 'kubectl events'
    abbr kevA 'kubectl events -A'
    abbr kevw 'kubectl events --watch'
    abbr kevwA 'kubectl events -A --watch'
    # explain (grc isn't super useful for explain so don't include it as I prefer tab complete here anyways)
    abbr kexplain 'kubectl explain'
    abbr kexplainr 'kubectl explain --recursive'
    # logs
    abbr kl 'kubectl logs'
    abbr klc 'kubectl logs --container='
    abbr klf 'kubectl logs --follow'
    abbr kla 'kubectl logs --all-containers=true --prefix'
    #   PRN: --previous, --timestamps, --since, --tail
    # plugin
    abbr kpls 'kubectl plugin list'
    # patch
    abbr kpatch 'kubectl patch'
    # port-forward
    abbr kpf 'kubectl port-forward' # setup proxy to access pod's port from host machine # ~ docker container run -p flag
    # replace
    abbr kr 'kubectl replace --force' # delete and then create
    abbr krf 'kubectl replace --force -f'
    # krew
    abbr krew 'kubectl krew'
    # (r)oll(o)ut
    abbr kro 'kubectl rollout'
    abbr kror 'kubectl rollout restart'
    abbr krorf 'kubectl rollout restart -f'
    abbr krost 'kubectl rollout status'
    abbr kroh 'kubectl rollout history'
    abbr krohf 'kubectl rollout history -f'
    abbr kropause 'kubectl rollout pause'
    abbr kroresume 'kubectl rollout resume'
    abbr kroundo 'kubectl rollout undo'
    # run
    abbr krun 'kubectl run --rm -i -t --image weshigbee/tools-net tmp -- bash' # ~ docker container run
    # scale
    abbr kscale 'kubectl scale'
    # set
    abbr kset 'kubectl set'
    # top
    abbr ktop 'kubectl top pod --all-namespaces'
    #
    abbr ktopw '$WATCH_COMMAND --no-title -- grc --colour=on kubectl top pod --all-namespaces'
    abbr ktopn 'kubectl top node'
    # version
    abbr kver 'kubectl version'
    # wait
    abbr kw 'kubectl wait' # FYI can go back to kwait if want w for other abbr

    # kubectl label
    # kubectl annotate
    # kubectl autoscale
    # kubectl expose
    # kubectl proxy
    # debug # TODO flesh out later, just a reminder:
    abbr kdebug 'kubectl debug'
    abbr kdebuge 'kubectl debug -it --image=weshigbee/tools-net pod/' # add+attach ephemeral container to pod/foo
    abbr kdebugc 'kubectl debug -it --image=weshigbee/tools-net --copy-to=tmp pod/' # clone+attach pod/foo
    abbr kdebugn 'kubectl debug -it --image=weshigbee/tools-net node/' # attach to node/foo's namespaces
    # kubectl options
    # kubectl alpha

    # *** conte(x)t
    #   => muscle memory: `dxls`=`docker context ls`, so => kxls
    abbr kx 'kubectl config'
    #
    # abbr --set-cursor -- kxs 'kubectl config set-context --current --namespace=%' # kxsn if want more set abbr's
    # abbr --set-cursor -- kns 'kubectl config set-context --current --namespace=%' # this is easier to remember BUT does not fit into kx abbr "namespacing" (pun intended)
    function kns
        # use kns so I can add namespace completion (below) => PRN could attempt fix to kubectl completion (doesn't work on --namespace flag)
        kubectl config set-context --current --namespace $argv
    end
    complete -c kns -a '(kubectl get namespace -o custom-columns=:metadata.name)' --no-files
    #
    abbr kxu 'kubectl config use-context'
    abbr kxls 'kubectl config get-contexts'
    abbr kxv 'kubectl config view'

    # rancher resources (fully qualify when overlapping, i.e. clusters)
    # abbr kgu 'kubectl get users.management.cattle.io'
    abbr kgu 'kubectl get users.management.cattle.io -o custom-columns=NAME:metadata.name,DISPLAYNAME:displayName,USERNAME:username,DESC:description' # add username/displayName
    # maybes:
    #  projects
    #  plans.upgrade.cattle.io
    #  clusters.management.cattle.io
    #
    #   clustergroups
    #   groups
    #   groupmembers
    #   globalroles
    #   globalrolebindings
    #   apps
    #   clusterrepos
    #   addons
    #   nodes.management.cattle.io
    #   preferences
    #   settings
    #
    #
    # fleet
    #   gitrepos
    #   bundles
    #   contents
    #   helmapps
    #   fleetworkspaces
    #
    # helm
    #   helmcharts
    #   helmchartconfigs

end

if command -q dig; and status is-interactive
    function dig --description 'alias dig grc dig'
        grc dig $argv
    end
end

if command -q kubectl-shell
    # docker labs debug equivalent for k8s
    abbr ksh kubectl-shell
    abbr kshn 'kubectl-shell --namespace'
    # --container foo
    # --namespace bar
    # --as/--as-group/--as-uid
    abbr kshc 'kubectl-shell --container'

    # add completions (are these overriden by ordering of loading ~/.config/fish/completions/kubectl-shell.fish?)
    complete -c kubectl-shell -a '(kubectl get pod -o custom-columns=:metadata.name)' --no-files
end

if command -q base64
    abbr d64 'base64 -d' # decode
    abbr e64 'base64 -e' # encode

    # prn others (prolly never use 32, but keep it as a reminder if I encounter others)
    abbr d32 'base32 -d'
    abbr e32 'base32 -e'

end

if command -q minikube

    abbr mk minikube
    abbr mkst 'minikube status'
    abbr mkstop 'minikube stop'
    abbr mkstart 'minikube start'
    abbr mkpause 'minikube pause'
    abbr mkunpause 'minikube unpause'
    abbr mkd 'minikube delete'
    abbr mkda 'minikube delete --all'

    abbr mks 'minikube ssh' # just like `vs` for `vagrant ssh`

    abbr mkn 'minikube node list'

    abbr mkdash 'minikube dashboard --port 9090'
    # service
    abbr mksls 'minikube service list' # any service type
    # PRN # minikube service --all --namespace _ # open all
    # not sure I see much of a reason to use minikube service when I can use kubectl port-forward and that is consistent across k8s-in-docker distros
    abbr mkt 'minikube tunnel --cleanup' # make LoadBalancer services routeable from host
    #   FTR tunnel allows to connect to load balanced service vs single pods w/ port-forward
    # addons
    abbr mka 'minikube addons list'
    abbr mkao 'minikube addons open'
    abbr mkae 'minikube addons enable'
    abbr mkad 'minikube addons disable'
    abbr mkai 'minikube addons images' # i.e. `minikube addons images registry`
    abbr mkac 'minikube addons configure'

    abbr mkde 'eval $(minikube docker-env)' # (d)ocker-(e)nv - access nested docker containers w/o nested (uncustomized) shell
    # abbr mkpe 'eval $(minikube podman-env)' # (p)odman-(e)nv - access nested podman containers w/o nested (uncustomized) shell

    abbr mkp 'minikube profile list'

    abbr mkcp 'minikube cp'
    abbr mkip 'minikube ip'

    # logs
    abbr mkl 'minikube logs'
    abbr mklf 'minikube logs --follow' # i.e. pause/unpause while watching
    abbr mkla 'minikube logs --audit'
    # ? mklp => 'minikube logs --problems'
    # --node # defaults to primary control plane node

    abbr mkv 'minikube version'

    # PRN:
    #  image, cache

end

# helm
if command -q helm

    abbr h helm

    # create      create a new chart with the given name
    #
    # dependency/dep/dependencies  manage a chart's dependencies
    #    build       rebuild the charts/ directory based on the Chart.lock file
    #    list        list the dependencies for the given chart
    #    update      update charts/ based on the contents of Chart.yaml
    #
    # env         helm client environment information
    #    abbr he 'helm env' # likely to remove this
    #
    # get         download extended information of a named release
    #    all         download all information for a named release
    abbr hga 'helm get all'
    #    hooks       download all hooks for a named release
    abbr hgh 'helm get hooks'
    #    manifest    download the manifest for a named release
    abbr hgm 'helm get manifest' # likely to use often
    abbr --set-cursor -- hgk 'helm get manifest % | kubectl get -f -'
    #  hgk j<TAB> =>   helm get manifest jenkins | kubectl get -f -
    #    metadata    This command fetches metadata for a given release
    abbr hgmetadata 'helm get metadata' # likely won't use often
    #    notes       download the notes for a named release
    abbr hgn 'helm get notes'
    #    values      download the values file for a named release
    abbr hgv 'helm get values'
    #
    # help        Help about any command
    # history/hist     fetch release history
    abbr hh 'helm history'
    # install     install a chart
    abbr hin 'helm install'
    # lint        examine a chart for possible issues
    # list/ls        list releases
    abbr hls 'helm list -A' # PRN default list args?
    # package     package a chart directory into a chart archive
    # plugin      install, list, or uninstall Helm plugins
    #    install/all     install one or more Helm plugins
    #    list/ls        list installed Helm plugins
    abbr hplls 'helm plugin ls'
    #    uninstall/rm/remove   uninstall one or more Helm plugins
    #    update/up      update one or more Helm plugins
    #
    # pull/fetch        download a chart from a repository and (optionally) unpack it in local directory
    abbr hp 'helm pull'
    abbr hpu 'helm pull --untar --untardir ./untar' # repo/chart arg => extract chart => ./untar/<chart-name>
    # push        push a chart to remote
    #
    # registry    login to or logout from a registry
    # repo        add, list, remove, update, and index chart repositories
    #    add         add a chart repository
    abbr hra 'helm repo add'
    #    index       generate an index file given a directory containing packaged charts
    #    list/ls        list chart repositories
    abbr hrls 'helm repo ls'
    #    remove/rm      remove one or more chart repositories
    abbr hrrm 'helm repo remove'
    #    update      update information of available charts locally from chart repositories
    abbr hrup 'helm repo update'
    # rollback    roll back a release to a previous revision
    #
    # search      search for a keyword in charts
    #    hub         search for charts in the Artifact Hub or your own hub instance
    #    repo        search repositories for a keyword in charts
    abbr hsh 'helm search hub' # local repos, no args = list all
    abbr hsr 'helm search repo' # remote
    abbr hsv 'helm search repo --versions ' # list versions
    #
    # show/inspect   show information of a chart
    abbr hi 'helm inspect'
    #    all         show all information of the chart
    #    chart       show the chart's definition
    abbr --set-cursor -- hic "helm show chart % | yq"
    #    crds        show the chart's CRDs
    #    readme      show the chart's README
    abbr --set-cursor -- hir "helm show readme % | bat -l md"
    #    values      show the chart's values
    abbr --set-cursor -- hiv "helm show values % | yq"
    #
    # status      display the status of the named release
    abbr hst 'helm status'
    #
    # template    locally render templates
    # abbr --set-cursor -- ht 'helm template % | yq' # repo/chart-name
    abbr ht 'helm template'
    function helm_template_diff
        # usage:
        #   helm_template_diff <chart> <version1> <version2>
        #   helm_template_diff jenkins/jenkins 3.11.1 5.1.0

        set -l chart $argv[1]
        set -l version1 $argv[2]
        set -l version2 $argv[3]

        icdiff -L "$chart --version $version1" \
            (helm template $chart --version $version1 | psub) \
            -L "$chart --version $version2" \
            (helm template $chart --version $version2 | psub)
    end
    #
    # test        run tests for a release
    # uninstall/delete/un/del   uninstall a release
    abbr hun 'helm uninstall'
    # upgrade     upgrade a release
    abbr hup 'helm upgrade'
    # verify      verify that a chart at the given path has been signed and is valid
    # version     print the client version information
    abbr hver 'helm version' # FYI - TODO - consistently define Xver across all tools I use, where version is regularly checked
end

# *** searching ***
#
abbr els "env | bat --language dotenv -p"
abbr egr "env | grep -i "
abbr env "env | bat -l env" # do this to fix color issues with LESS_TERMCAP_** env vars
# alternative: strip CSI escape codes from LESS_TERMCAP_* env vars (and possibly others)
# env | string replace --regex "\\x1b\[1(;\\d+)+m" ""
#
# shell variables names and values
abbr vls "set | bat --language ini -p"
abbr vgr "set | grep -i "
#
# abbr's
abbr --add agr --set-cursor "abbr | grep -i '%'"
abbr --add agrs --set-cursor "abbr | grep -i '\-\- %'" # starts with b/c `-- name` is consistent format of abbr's list output
#
# complete's
abbr --set-cursor completeC "complete -C '%'"
#
#   abbr --list | grep -i '^an' # another avenue if I have too much trouble relying on `abbr --show` + grep
#
# AFAICT there's no way to lookup an abbr by name... and get its executable format
#   Also, not straight forward to parse the executable format b/c name can appear in many different spots
#
#   abbr --show  # lists all, in executable format
#   abbr --query foo # can check if name exists
#   abbr --show --query foo # would be nice to combine query with show!
#   abbr --list # shows just the list of names
#
# Nice to haves:
#   FYI I have a feature branch hack of combining --query and --show:
#     https://github.com/g0t4/fish-shell/tree/feature-abbr-lookup
#     but don't work on this any more unless grep absolutely falls apart
#

# *** binds (consolidate here) ***
# FYI fish4 OOB has:
#   alt-. history-token-search-backward
#   alt-up history-token-search-backward
#   alt-down history-token-search-forward
#   FYI other shells use Escape-. but fish 4 has up/down which is superior, so use that
#   should I want to retrain myself on escape-. then add this back:
#   bind_both_modes_default_and_insert escape,. history-token-search-backward

# *** processes ***
abbr psg "grc ps aux | grep -i "
if $IS_MACOS
    # pgrep macos:
    #   -l long output (list process name too, also w/ -f prints arg list)
    #   -a include pgrep's process ancestors in the match list (i.e. if using sudo pgrep) => they are hidden by default (unlike linux)
    #      # yes include -a... for example, I might be matching on "fish" and so I wanna see that
    #      # FYI if I use grc in front of pgrep... then that grc process always matches b/c its an ancestor... so for now lets get rid of default using grc to avoid that frustration
    #   -f/-i - same as linux
    abbr pgrep "pgrep -ilfa"
    # TLDR -a is added for different reasons between macOS and linux but for now I want it on both
    #

    abbr pgrepu 'pgrep -U $USER -ilfa'

    # -l is only on macOS
    # -i/-f are same as pgrep
    abbr pkill "pkill -ilf" # same options as pgrep (-l (long) shows underlying kill command used per PID)
    abbr pkill9 'pkill -9 -ilf'
    abbr pkillu 'pkill -U $USER -ilf'
    abbr pkill9u 'pkill -9 -U $USER -ilf'

else if $IS_LINUX
    # -i ignore case (same as mac)
    # -f match full arg list (same as mac)
    # -l == list process name too, not just PID (mac does this too)
    #       however, unlike a mac, -lf together doesn't include arg list
    # -a show full command line (args too)
    # -A ignore pgrep's ancestor processes (on by default and I hate that => always matches self)
    #    FYI if I get rid of -a on mac variant, then I probably wanna add -A here (not remove -a here)... to mirror the exclusion of ancestors
    abbr pgrep "pgrep -ilfa"
    abbr pgrepu 'pgrep -U $USER -ilfa'

    # -l is NOT on linux version
    # -i/-f are same as pgrep
    abbr pkill "pkill -if" # same options as pgrep (-l (long) shows underlying kill command used per PID)
    abbr pkill9 'pkill -9 -if'
    abbr pkillu 'pkill -U $USER -if'
    abbr pkill9u 'pkill -9 -U $USER -if'

    # FYI I might still be missing some differences w/ linux... I didn't review all possible pgrep/pkill args

end
abbr psfull "grc ps -o 'user,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm' -ax"
if $IS_LINUX
    # not sure I wanna even try to replicate this on mac as then I might habituate wanting a different command, I like this alot on linux for showing current shells and their hierarchy of processes
    abbr psf "grc ps f" # i.e. current shells in tree view on linux
end
#
# NOTES:
# - keep non-format options on end of cmd to easily toggle:
# - user:10 - limits to 10 chars (+ indicates ...) (:X ubuntu yes, macos no):
#       ps -o "user:5,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm" -ax
#
# *** MY pstree
abbr --set-cursor -- pstreeg "pstree_grep '%'"
abbr --set-cursor -- pstreeg_watch "\$WATCH_COMMAND --shell fish 'pstree_grep \"%\"'"

# *** pstree
# pstreeX => pstree -l X
abbr --add _pstreeX --regex "pstree\d+" --function pstreeX
function pstreeX
    string replace pstree 'pstree -l' $argv
end
abbr pstrees --set-cursor 'pstree -s "%"' # *** NEW FAVORITE, shows all matching parents/descendants (IIUC)
abbr pstreep 'pstree -p' # parents/descendants of PID, without -p then its just descendants
abbr pstreet 'pstree  (ps -o pid=)' # ps gives processes w/ controlling terminal, then pstree shows their hierarchy... similar to "ps f" on *nix
abbr pstreeU 'pstree -U' # skip root only branches
abbr pstreeu 'pstree -u $(whoami)' # my processes
abbr pstreew 'pstree -w' # wide output (otherwise truncated)
# TODO pstree on macos/linux differs - reconcile abbrs based on env? use macos rooted abbrs (i.e. pstrees => pstree -s) but then have it map to smth similar on linux?
function pstree
    # TODO use -g 2 by default on macOS (looks better IMO)
    command pstree -g 2 $argv
end
# TODO look into utils like fuser (not necessarily for abbrs, though maybe) but b/c I need to shore up my knowlege here, so much easier to diagnose what an app is doing if I can look at its external interactions (ie files, ports, etc)

# *** sed ***

set --global sed_cmd sed
if $IS_MACOS
    set sed_cmd gsed
    abbr sed gsed # encourage gsed for uniform w/ linux distros
    #  i.e. gnu allows `sed -i` whereas BSD requires the extension `sed -i''` be passed
end
#
# * general sed abbrs:
abbr --set-cursor sede "$sed_cmd -Ei 's/%//g'"
abbr --set-cursor sedd "$sed_cmd --debug -i 's/%//g'"
abbr --set-cursor sedi "$sed_cmd -i 's/%//g'"

# * examples (can nuke if need be)
# abbr sed_duplicate_lines $sed_cmd' \'N; /^\(.*\)\n\1$/!P; D\' file'

# rg => (rg --files-with-matches __)
# use rg to limit which files are passed to sed (so not touching all files)
# use this to take your sed search regex and limit the files and then the file names are passed back
abbr --set-cursor --command $sed_cmd --position=anywhere -- rg "(rg --files-with-matches %)"

function build_sed_abbrs_for_filetype
    # FYI there may be some bugs here in porting this, just heads up... use and find out

    set -l filetype_letter $argv[1]
    set -l glob_end $argv[2]
    set -l _abbr "sed$filetype_letter"

    # * two approaches to making it easier to target specific files...
    set rg_filter "(rg -g '*.$glob_end' --files-with-matches ___)"

    # 1. dedicated abbr per file type(s)
    abbr --set-cursor $_abbr "$sed_cmd -Ei 's/%//g' $rg_filter"

    # 2. *l => (rg -g "*.lua" --files-with-matches ___)
    abbr --command $sed_cmd --position=anywhere "*$filetype_letter" $rg_filter
end
build_sed_abbrs_for_filetype l lua
build_sed_abbrs_for_filetype t ts
build_sed_abbrs_for_filetype j "{json,js}"
build_sed_abbrs_for_filetype m md
build_sed_abbrs_for_filetype p py

# all -  use rg w/o a filter on language (no -g *.lua for example)
abbr --set-cursor seda "$sed_cmd -Ei 's/%//g' (rg --files-with-matches ___) "
abbr --command $sed_cmd --position=anywhere "*a" "(rg --files-with-matches ___) "

abbr _cat_range --function _cat_range_abbr --regex "(catr|catrange|sedr|sedrange)\d+_\d+"
function _cat_range_abbr
    # purpose:   cat range -n '10,25p' foo.txt
    set matches (string match --regex "(\d+)_(\d+)" $argv[1])
    set start $matches[2]
    set end $matches[3]
    echo "$sed_cmd -n '$start,$end""p'"
end

# *** dns
# TODO port more dns/arp helpers here
function _flush_dns
    # PRN check if macos, if not use different command or warn
    sudo killall -HUP mDNSResponder
end

function kill_hung_grc
    # if grc hangs (ie due to invalid config) then use this
    # kill grcat is all you need, the grc process dies after
    pkill -ilf grcat
end

abbr z_clean 'z --clean' # mostly a reminder, removes non-existant directories from z history file
function z
    # TLDR = wcl + z
    # FYI still uses z fish completions (b/c same name)

    # -- ensures $argv can have options to z (i.e. --clean)
    if string match --quiet --regex "https://(?<z_domain>[^/]+)/(?<z_repo>.+)" -- $argv
        # TODO also work w/o https:// on front?
        # echo $z_domain
        # echo $z_repo
        # that said... I am using --path-only below to map to a dir... so I don't need the capture groups

        # if a repo url then clone and/or cd to it
        set path (wcl --path-only $argv)
        if test -d $path
            # PRN wcl anyways to get latest? wouldn't that be what I want when I pass a full URL http://...?
            cd $path
        else
            wcl $argv
            cd $path
        end
    else
        # PRN in future detect if org/repo format ($argv)... AND if z has no matching results... then attempt to clone and cd to it...?
        # otherwise just call z like normal
        # TODO __z --delete does not take a path! it deletes curent dir...
        #   I want to modify this to add support to delete a path
        #   and all subpaths (maybe -R)

        __z $argv
    end
end

# * z --echo
abbr --position=anywhere --set-cursor --function _abbr_ze -- ze
function _abbr_ze
    # intended to easily select a directory for another outer command, or just print a path
    # i.e.:
    #    mv foo.txt ze<SPACE> => mv (z --echo _)
    #    ze<SPACE> => z --echo _
    #       # or ... what about:
    #       echo (z --echo _)?
    #
    # echo "'"(commandline -b)"'"
    # return
    if string match --quiet --regex '^ze $' (commandline -b)
        # only 'ze ' at start of line, then don't use cmd substitution
        echo 'z --echo'
        return
    end
    echo '(z --echo %)' # insert z --echo so you can pick a path to include in another outer command
end

# *** terraform
if command -q terraform

    abbr tf terraform

    abbr tfv 'terraform validate' # *** favorite
    abbr tfi 'terraform init'
    abbr tfimport 'terraform import'
    abbr tff 'terraform fmt'
    abbr tfa 'terraform apply'
    abbr tfp 'terraform plan'
    abbr tfo 'terraform output'

    abbr tfshow 'terraform show' # dump all resources in state
    #
    abbr tfs 'terraform state' # subcommands
    abbr tfsl 'terraform state list' # list resources currently in state
    abbr tfss 'terraform state show' # dump one resource in state
    abbr tfsrm 'terraform state rm' # remove resource from state
    abbr tfr 'terraform refresh'

    abbr tfd 'terraform destroy'
    abbr tft 'terraform taint'
    abbr tfu 'terraform untaint'

end

# *** bindings
#
# idea: shortcut to change to command position and replace command (type new command), i.e.:
#    ls /etc/docker/daemon.json
#    # shortcut: ctrl+shift+delete
#    _ /etc/docker/daemon.json
#    cat /etc/docker/daemon.json
function custom-kill-command-word
    # PRN move to start of current command in a pipeline of multiple commands
    commandline -f beginning-of-line
    commandline -f kill-word
end
# ctrl+ins
bind_both_modes_default_and_insert ctrl-o custom-kill-command-word # ctrl +o ([o]verwrite command)
# bind_both_modes_default_and_insert  '*' custom-kill-command-word # * alone works w/o interrupt mid suggestion
# ctrl+o/q unbound currently IIUC
# '[1;5H' # ctrl+home (interrupts suggestion)
# '[1;6H' # ctrl+shift+home (rest seem to interrupt too, likely b/c bound to smth else and triggering two bindings, maybe? i.e. home moves to home)
# '[1;7H' # ctrl+alt+home
# '[1;13H' # ctrl+alt+home
#    H=>F (home=>end key)
#
function toggle-grc
    # PRN port to zsh/pwsh

    # can easily ditch grc in kubectl command to get tab completions to work and add it back to color output and then pull back history of previous command and switch it off to tab complete easily again and grc to run it when done
    #   PRN turn off grc by default in abbrs where tab completion is often used and doesn't work well w/ grc
    #   also I am well aware that I should get grc tab completion fixed and I will look into that too
    set -f cmd (commandline)
    if test -z $cmd
        # if empty cmd, then use last command (and thus toggle its grc)
        # idea is, run command and be like oh no I wanted grc, then bam run it again, or vice versa
        set cmd (history | head -n 1)
    end

    if string match --quiet --regex "^grc\s" -- $cmd
        set cmd (string replace --regex -- "^grc\s+" "" $cmd)
        commandline -r $cmd
    else
        fish_commandline_prepend grc
        return
    end
    # ALTERNATIVE - pull back last command, toggle-grc, run - can use if I find myself doing this two step process often
end
bind_both_modes_default_and_insert ctrl-q toggle-grc # terrible key choice (ctrl+q) but it isn't used currently so yeah

function toggle-git_commit_command
    # toggle wrapping current command line in a git commit
    # to commit changes w.r.t. running a command
    # for example:
    #   uv add ipykernel
    #   => git commit -m 'uv add ipykernel'
    set -f cmd (commandline)
    if test -z "$cmd"
        # if empty cmd, then use last command
        # pull back last non git command (so I can stage files and then commit)
        set cmd (history | grep -v '^git\s' | head -n 1)
    end

    if string match --quiet --regex "^git\scommit\s-m\s" -- $cmd
        # unwrap
        # use regex capture group to extract the message part only (strip quotes too)
        set cmd (string replace --regex -- "^git\scommit\s-m\s'(.*)'" "\1" -- $cmd)
        commandline -r $cmd
    else
        # wrap
        commandline -r "git commit -m '$cmd'"
        return
    end
end

bind_both_modes_default_and_insert ctrl-f12 toggle-git_commit_command
# FYI -M default applies to both vi/emacs modes... default==normal in vi-mode

if command -q apt

    # start on apt helpers now that I have fish in almost all of my ubuntu environments

    abbr apts 'apt search'
    abbr apti 'sudo apt install'
    abbr aptu 'sudo apt update'
    abbr aptug 'sudo apt upgrade'

    abbr aptl 'apt list --installed'
    abbr aptlu 'apt list --upgradable'

    abbr aptcm 'apt-cache madison'

    abbr dpkgL 'dpkg -L' # list files installed by package
    abbr dpkgS 'dpkg -S' # search for package that owns file

    function dpkg_L_files
        dpkg -L $argv | xargs -I {} echo 'test ! -d "{}"; and echo "{}"' | source
    end

    complete -c dpkg_L_files -a '(dpkg --get-selections | grep -w "install" | awk \'{print $1}\')' --no-files

    function dpkg_L_tree
        # uses exa to append icons (left side only), pipes to awk to put icon on right side, pipes to treeify and icon ends up on right side
        exa (dpkg_L_files usbutils) --icons=always | awk '{icon=$1; $1=""; sub(/^ /, ""); print $0, icon}' | treeify
    end

    complete -c dpkg_L_tree -w dpkg_L_files

    if not command -q treeify
        function treeify
            echo "treeify not installed, please install it with 'cargo install treeify'"
        end
    end

end

if command -q watch; and status is-interactive
    # VERIFIED watch does this on both macos and ubuntu

    # FYI this is faster than using alias and more obvious what happens:
    function watch
        # FYI uses same pattern of passing $argv as is found in fish's alias helper
        TERM=xterm command watch $argv
        # if watch believes there are 16+ colors (8 regular + 8 brights) it will then init the brights to hard coded colors and screw up background colors too (i.e. for white)... so if it believes there are only 8 colors then it doesn't alter any of them IIUC: https://gitlab.com/procps-ng/procps/-/blob/master/src/watch.c#L181

        # good way to test my colors:
        # watch -n 0.5 --color -- "grc --colour=on kubectl describe pod/web"

        # IIUC viddy doesn't have --color? Do I want to add it to just this watch wrapper?
    end

    function viddy
        # look in args for `-n` and then don't pass if found
        if contains -- -n $argv
            command viddy $argv
        else
            command viddy -n $WATCH_INTERVAL $argv
        end
    end

    export WATCH_INTERVAL=0.5
    if command -q viddy
        set WATCH_COMMAND viddy
    else
        set WATCH_COMMAND watch
    end
    abbr watch $WATCH_COMMAND
    abbr wa $WATCH_COMMAND
    # FYI if you go back to watch... add --color to appropriate abbrs
    abbr wag '$WATCH_COMMAND --no-title -- grc --colour=on'
    # to support --no-title, add --show-kind to kubectl get output
    # - saves top title line and blank line after it for screen realestate!
    # - also nukes showing time in upper right corner
    # - FYI --show-kind already enabled if multi types requested, so NBD
    abbr wak '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind' # using alot! I love this
    abbr wad '$WATCH_COMMAND --no-title -- grc --colour=on kubectl describe --show-kind' # using alot! I love this
    abbr wakp '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind pods'
    abbr wah '$WATCH_COMMAND --no-title -- http --pretty=colors'
    abbr wahv '$WATCH_COMMAND --no-title -- http --pretty=colors --verbose' # == --print HhBb (headers and body for both request and response)
    abbr wal '$WATCH_COMMAND --no-title -- grc --colour=on ls'
    abbr wat '$WATCH_COMMAND --no-title -- grc --colour=on tree'
    # for k8s prefer kubectl --watch b/c grc colors the output w/o issues.. but when it is not avail to continually monitor then use watch command w/ color output:
    #   watch -n0.5 --color -- grc --colour=on kubectl rollout status deployments

    # FYI find terminfo for a TERM value:
    #    diff_two_commands 'infocmp xterm' 'infocmp xterm-256color'
    #
    # xterm = treated as 8 color
    # FYI xterm-16color still has brights issue
    # xterm-256color = treated as 256 colors (IIUC this is how background colors for bright white gets messed up)

end

abbr wc wordcount # when typing wc => expand into custom wordcount func (can still use `wc` in scripts or `command wc` to use wc directly)
function wordcount
    # run wc and then parse result to add labels on each value:
    wc $argv | command awk '{printf("lines: %'\''d\nwords: %'\''d\nchars: %'\''d\n", $1, $2, $3)}'
    # FYI comma delimitted support in awk is not POSIX compliant, but is supported in gawk and mawk IIUC
end

if command -q yq

    # helper to select a document by index from multidocument yaml file
    abbr pyqi "| yq eval 'select(documentIndex == 1) | .status'"
    abbr pyqp "| yq -P" # pretty print (clean/idiomatic yaml) == `yq '... style=""')`
    # FYI `jid < foo.json` can tab complete json property keys... but doesn't appear to support multiple documents (IIAC an put into an array to get it to work)

    function yq_diff_docs
        # usage:
        #   kubectl get pods -o yaml > pods.apply.watch.yaml
        #   yq_diff_docs pods.apply.watch.yaml  0 1 '.status'
        #   leave pair of #s so I can diff across indexes (should add optional arg for second documentindex for that... as mostly I would wanna compare before/after - sequential pairs)

        # PRN how about loop over each document pair in a watched file from k8s
        #   cat pods.apply.watch.yaml  | yq di
        #   IIUC no way to query # documents but can select document indexes or otherwise count lines to get # ... or just loop over document indexes and pair them with next to avoid any maths

        set file $argv[1]
        set doc1 $argv[2]
        set doc2 $argv[3]
        set path $argv[4]

        # https://mikefarah.gitbook.io/yq/operators/document-index
        yq eval "select(documentIndex == $doc1) | $path" $file >/tmp/doc1.yaml
        yq eval "select(documentIndex == $doc2) | $path" $file >/tmp/doc2.yaml

        icdiff -W -L "doc $doc1" /tmp/doc1.yaml -L "doc $doc2" /tmp/doc2.yaml
    end
end

# TODO brew install wader/tap/fq
#    fq = jq for binary files
#    https://github.com/wader/fq

# *** _list_<namespace>_<what>
abbr _reminders_docker_binfmts "docker run --privileged --rm tonistiigi/binfmt" # https://github.com/tonistiigi/binfmt
# idea for a new spot where I can locate what are essentially reminders for commands (i.e. not used often)
# type _reminders<TAB> to see what is available

# examples:
#    tellme_about docker   # executable, symlink
#    tellme_about ld       # executable, not symlink
function tellme_about
    set -l what $argv[1]
    set _where (command -v $what)
    if test -z $_where
        echo "I don't know about $what"
        return 1
    end
    echo $_where # top level match, no indent
    file --brief $_where | _indent # indent the description
    if test -L $_where
        echo "  -> " (readlink $_where) # show target
    end

    # todo multiple matches
    # PRN flesh this out later, just a quick thought... I feel like I've done this before too :)...
end

function _indent
    # $argv = level of indent (1 = 2 spaces, 2 = 4 spaces, etc)
    if test -z $argv
        set spaces 2 # default to 2 spaces (1 level of indent)
    else
        set spaces (math "$argv * 2") # 2 spaces per indent
    end
    sed "s/^/"(string repeat " " -n $spaces)"/"

end

if command -q act

    function actw_expanded

        # if not in repo root, prepend a cd too, mostly as a reminder to avoid pathing issues to the workflow files and also issues when run act inside a nested dir:
        if test (pwd) != (_repo_root)
            echo -n "cd \$(_repo_root); "
        end

        echo act --reuse --workflows .github/workflows/!

    end

    abbr --add actw --set-cursor --function actw_expanded

    # GENERATED COMPLETIONS (finagled chatgpt to spit this out):
    #
    # function generate_completions_from_help
    #     for line in (act --help | grep -oE "\-\-[a-zA-Z0-9-]+")
    #         set option (echo $line | sed 's/--//')
    #         echo complete -c act -l $option
    #     end
    # end
    #
    # generate_completions_from_help
    #
    complete -c act -l action-cache-path -d "Defines the path where the actions get cached and host workspaces created."
    complete -c act -l action-offline-mode -d "If action contents exist, it will not be fetched or pulled again."
    complete -c act -l actor -s a -d "User that triggered the event."
    complete -c act -l artifact-server-addr -d "Defines the address to which the artifact server binds."
    complete -c act -l artifact-server-path -d "Defines the path where the artifact server stores uploads and downloads."
    complete -c act -l artifact-server-port -d "Defines the port where the artifact server listens."
    complete -c act -l bind -s b -d "Bind working directory to container, rather than copy."
    complete -c act -l bug-report -d "Display system information for bug report."
    complete -c act -l cache-server-addr -d "Defines the address to which the cache server binds."
    complete -c act -l cache-server-path -d "Defines the path where the cache server stores caches."
    complete -c act -l cache-server-port -d "Defines the port where the cache server listens."
    complete -c act -l container-architecture -d "Architecture which should be used to run containers."
    complete -c act -l container-cap-add -d "Kernel capabilities to add to the workflow containers."
    complete -c act -l container-cap-drop -d "Kernel capabilities to remove from the workflow containers."
    complete -c act -l container-daemon-socket -d "URI to Docker Engine socket."
    complete -c act -l container-options -d "Custom docker container options for the job container."
    complete -c act -l defaultbranch -d "The name of the main branch."
    complete -c act -l detect-event -d "Use first event type from workflow as the event that triggered the workflow."
    complete -c act -l directory -s C -d "Working directory."
    complete -c act -l dryrun -s n -d "Dryrun mode."
    complete -c act -l env -d "Environment variables to make available to actions."
    complete -c act -l env-file -d "Environment file to read and use as env in the containers."
    complete -c act -l eventpath -s e -d "Path to event JSON file."
    complete -c act -l github-instance -d "GitHub instance to use, not for GitHub Enterprise Server."
    complete -c act -l graph -s g -d "Draw workflows."
    complete -c act -l help -s h -d "Help for act."
    complete -c act -l input -d "Action input to make available to actions."
    complete -c act -l input-file -d "Input file to read and use as action input."
    complete -c act -l insecure-secrets -d "Does not hide secrets while printing logs."
    complete -c act -l job -s j -d "Run a specific job ID."
    complete -c act -l json -d "Output logs in json format."
    complete -c act -l list -s l -d "List workflows."
    complete -c act -l local-repository -d "Replaces the specified repository and ref with a local folder."
    complete -c act -l log-prefix-job-id -d "Output the job id within non-json logs."
    complete -c act -l matrix -d "Specify which matrix configuration to include."
    complete -c act -l network -d "Sets a docker network name."
    complete -c act -l no-cache-server -d "Disable cache server."
    complete -c act -l no-recurse -d "Disable running workflows from subdirectories."
    complete -c act -l workflows -d "Path to workflow files."
    complete -c act -l no-skip-checkout -d "Do not skip actions/checkout."
    complete -c act -l platform -s P -d "Custom image to use per platform."
    complete -c act -l privileged -d "Use privileged mode."
    complete -c act -l pull -s p -d "Pull docker image(s) even if already present."
    complete -c act -l quiet -s q -d "Disable logging of output from steps."
    complete -c act -l rebuild -d "Rebuild local action docker image(s) even if already present."
    complete -c act -l remote-name -d "Git remote name used to retrieve URL of git repo."
    complete -c act -l replace-ghe-action-token-with-github-com -d "Set personal access token for private actions on GitHub."
    complete -c act -l replace-ghe-action-with-github-com -d "Allow specified actions from GitHub on GitHub Enterprise Server."
    complete -c act -l reuse -s r -d "Don't remove container(s) on successfully completed workflows."
    complete -c act -l rm -d "Automatically remove container(s)/volume(s) after a workflow(s) failure."
    complete -c act -l secret -s s -d "Secret to make available to actions."
    complete -c act -l secret-file -d "File with list of secrets to read from."
    complete -c act -l use-gitignore -d "Controls whether paths in .gitignore should be copied into container."
    complete -c act -l use-new-action-cache -d "Enable using the new Action Cache for storing Actions locally."
    complete -c act -l userns -d "User namespace to use."
    complete -c act -l var -d "Variable to make available to actions."
    complete -c act -l var-file -d "File with list of vars to read from."
    complete -c act -l verbose -s v -d "Verbose output."
    complete -c act -l version -d "Version for act."
    complete -c act -l watch -s w -d "Watch the contents of the local repo and run when files change."
    complete -c act -l workflows -s W -d "Specify path to workflow files."

end

if command -q az

    # *** do not try to add upfront, lol!

    abbr azal 'az account list --output table' # subscriptions
    abbr azall 'az account list-locations --output table' # locations

    # resources:
    abbr azrl 'az resource list --output table' # resources
    abbr azrs 'az resource show --output table' # resource show
    # resource groups:
    abbr azgl 'az group list --output table'

    # app services
    abbr azwl 'az webapp list --output table' # webapps
    abbr azasl 'az appservice plan list --output table' # service plans

end

# ** llama-cpp / llama-server related

abbr huggingface-cli hf
function hf
    # FYI new workflow appears to be:
    #   hf cache ls
    #   hf cache rm user/repo

    # TODO later
    #   hf --show-completion #... I can put this in ~/.config/fish/completions/hf.fish ... issue is the hf command doesn't exist so it can't generate completions w/o this function... ciruclar loop at best... FUUU

    # FYI (no longer need [cli] extras)
    # stop using arcane 0.36 ... newer has completions btw, transformers 4.X is tied to <1 btw so not gonna install newer in most venvs until 5 is RC'd
    uv tool run --from 'huggingface-hub>=1.1.7' hf $argv
end

# hf reserved for huggingface CLI (hf command now)
abbr hfc "hf cache"
abbr hfcls "hf cache ls"
abbr hfcrm "hf cache rm"
abbr hfcv "hf cache verify"
abbr hfcpr "hf cache prune"

if command -q llama-server

    # https://github.com/ggml-org/llama.cpp/blob/056eb745/common/arg.cpp#L1424-L1431
    # n_batch == https://github.com/ggml-org/llama.cpp/blob/056eb745/common/arg.cpp#L1442-L1448

    function _setup_llama_server

        # TODO where do I want this, if it gets merged upstream?
        # source (llama-server --completion-fish | psub)

        # PRN add some abbrs for higher ram usage if you frequently want that... and/or GET ANOTHER 5090 and max it all out!
        # TODO alter --cache-reuse ? 256 on --fim- presets... smaller, bigger? (how does it work with RoPE scaling? https://ggml.ai/f0.png)

        #   basically changes to the presetes --fim* for my plugin's differences... i.e. bigger batch size (limits to 1K tokens with --fim presets!!!)
        # FYI I want abbrs so I can see the params I am overriding...and that I am using spec or not
        set verbose --verbose --verbose-prompt
        set host --host 0.0.0.0 --port 8012

        # recommend sane defaults b/c it reserves this much GPU RAM upfront!
        #   IIAC, if I go over, I'll know b/c predictions will be terrible!... maybe find a way to catch that warning in the API call if possible (I know ollama shows in CLI output, at least... and IIAC that is from llama-cpp)
        # FYI part of the reason I am using abbrs... so I can override for a separate session easily... so yeah don't go for super high context length
        set batch_size --batch-size 2048 --ubatch-size 2048
        set batch_size_spec --batch-size 2048 --ubatch-size 2048
        set _spec7 llama-server --fim-qwen-7b-spec $host $batch_size
        set _spec14 llama-server --fim-qwen-14b-spec $host $batch_size
        set _default7 llama-server --fim-qwen-7b-default $host $batch_size

        # FYI I confirmed args override any earlier usages (including in preset combos)

        # First one is for mindlessly saying "just make it work"
        abbr lsq25 $_spec7
        # other presets to select from with tab completion
        abbr lsq25nonspec7 $_default7
        abbr lsq25spec7 $_spec7
        # FYI no 14-default (non-spec)
        abbr lsq25spec14 $_spec14
        abbr lsverbose_q25nonspec $_default7 $verbose
        abbr lsverbose_q25spec7 $_spec7 $verbose
        abbr lsverbose_q25spec14 $_spec14 $verbose

        # * llama-server args for llama.[vim|vscode] FIM predictions
        #   diff settings, keep more of presets given the presets were designed for llama.vim
        set _spec7 "llama-server --fim-qwen-7b-spec $host"
        set _spec14 "llama-server --fim-qwen-14b-spec $host"
        set _default7 "llama-server --fim-qwen-7b-default $host"

        # FYI 4k --context-size if not specified
        set _qwen3coder_host "--host 0.0.0.0 --port 8013"
        set _qwen3coder_shared "llama-server $_qwen3coder_host --ctx-size 65536 --batch-size 2048 --ubatch-size 2048 --flash-attn on --n-gpu-layers 99"
        # IIUC both qwen2.5-coder and qwen3-coder models share the same vocab though I should double check
        # set _draft_fimq25_05b "--hf-repo-draft ggml-org/Qwen2.5-Coder-0.5B-Q8_0-GGUF"
        # TODO! try ncache reuse arg at 256? which is in llama-server repo's arg for this
        # set qwen3coder_q4 "$qwen3coder_shared -hf TODO make myself? $_qwen3coder_host"
        set qwen3coder_q8 "$_qwen3coder_shared -hf ggml-org/Qwen3-Coder-30B-A3B-Instruct-Q8_0-GGUF"
        # set qwen3coder_q8_spec "$_qwen3coder_shared $_draft_fimq25_05b -hf ggml-org/Qwen3-Coder-30B-A3B-Instruct-Q8_0-GGUF"
        # lol ok spec dec sometimes is fast, othertimes is terribly slow, qwen2.5coder must not be a good fit for this?
        # abbr lsqwen3coderq4 $qwen3coder_q4
        # abbr lsqwen3coderq4_verbose $qwen3coder_q4 $verbose
        abbr lsqwen3coderq8 $qwen3coder_q8
        # abbr lsqwen3coderq8_spec $qwen3coder_q8_spec
        abbr lsqwen3coderq8_verbose $qwen3coder_q8 $verbose

        # TODO qwen3 specdec using qwen2.5-coder 0.5B? if so then maybe go FP16 for qwen3-coder to have best fidelity?

        # TODO --batch-size / --ubatch-size # memory impact?
        # --ctx-size 0 => means load from model or default 4096
        set _gptoss_host "--host 0.0.0.0 --port 8013"
        set _gptoss_shared "llama-server $_gptoss_host --batch-size 2048 --ubatch-size 2048 --ctx-size 0 --jinja --flash-attn on --n-gpu-layers 99 --reasoning-format none"
        abbr lsgptoss20b "$_gptoss_shared -hf ggml-org/gpt-oss-20b-GGUF"
        abbr lsgptoss120b "$_gptoss_shared -hf ggml-org/gpt-oss-120b-GGUF"
        # TODO speculative decoding with ngram?! or 20b draft feeds 120b judge

        # * Seed-Coder
        set _bytedance_host "--host 0.0.0.0 --port 8012"
        set _bytedance_shared "z base; llama-server $_bytedance_host --batch-size 2048 --ubatch-size 2048 --ctx-size 0 --jinja --flash-attn on --n-gpu-layers 99"
        abbr lsbytedance_seed_coder_4 "$_bytedance_shared --model ByteDance-Seed-Coder-8B-Base-Q4_K_M.gguf"
        abbr lsbytedance_seed_coder_8 "$_bytedance_shared --model ByteDance-Seed-Coder-8B-Base-Q8_0.gguf"
        abbr lsbytedance_seed_coder_f16 "$_bytedance_shared --model ByteDance-Seed-Coder-8B-Base-f16.gguf"

    end
    _setup_llama_server
end

if command -q ollama
    abbr olc "ollama create"
    abbr olcp "ollama cp"
    abbr ole "export OLLAMA_HOST='ollama:11434'"

    # * list
    abbr olh "ollama help"
    #
    abbr ollnaked "grc ollama list"
    # until I get colors worked out so they're not positional (i.e. column X) then I'll default to bat coloring:
    # abbr --set-cursor -- oll 'ollama list | awk \'{OFS="\t" } /%/ { print $3$4,$1,$2,$5" "$6" "$7" "$8" "$9 }\' | sort -h | bat -l tsv --color=always | column -t'
    # FYI CURSOR is between // in awk so I can filter too!!!
    abbr --set-cursor -- oll 'ollama list | awk \'{OFS="\t" } /%/ { print $3$4,$1,$2,$5" "$6" "$7" "$8" "$9 }\' | sort -h | column -t | grcat conf.ollama_list'
    #
    abbr ollqwen3coder "grc ollama list qwen3-coder"
    abbr ollqwen25coder "grc ollama list qwen2.5-coder"
    abbr ollqwen25 "grc ollama list qwen2.5:"
    abbr ollqwen3 "grc ollama list qwen3:"
    abbr ollgptoss "grc ollama list gpt-oss"

    abbr olp "ollama pull"
    abbr olps "ollama ps"
    abbr olpush "ollama push"
    abbr olr "ollama run --verbose"
    abbr olrm "ollama rm"

    # PRN - use grc with ollama serve too and write my own coloring config (have claude do it)... do this if I dislike using bat for this
    set -l _ollama_serve "ollama serve 2>&1 | bat -pp -l log" # -pp to disable pager and use plain style (no line numbers).. w/o disable pager, on mac my pager setup prohibits streaming somehow (anyways just use this always)
    # OLLAMA_NUM_PARALLEL is to ensure maximum context size for a single request n_ctx (not split up by --parallel, which defaults to 4 on smaller qwen models)
    # OLLAMA_CONTEXT_LENGTH=8192 - num_ctx/n_ctx defaults to 2048... leads to truncation, set this here for OpenAI APIS that don't allow it as a parameter on a request
    # OLLAMA_KEEP_ALIVE=30m
    abbr olsl "OLLAMA_NUM_PARALLEL=1 $_ollama_serve"
    abbr olsld "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 $_ollama_serve"
    #
    abbr olsg "OLLAMA_NUM_PARALLEL=1 OLLAMA_HOST='http://0.0.0.0:11434' $_ollama_serve"
    abbr olsgd "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 OLLAMA_HOST='http://0.0.0.0:11434' $_ollama_serve"
    #
    # * ollama config code: https://github.com/ollama/ollama/blob/main/envconfig/config.go
    #    i.e. OLLAMA_KEEP_ALIVE=10m0s
    #
    # I am starting to understand the value of just serving a single model at a time (per endpoint)... i.e. to control params through env vars and not worry about model to model differences
    abbr olsq ols_qwen
    abbr olsqd ols_qwen_debug
    set _ollama_qwen "OLLAMA_CONTEXT_LENGTH=8192 OLLAMA_KEEP_ALIVE=10m OLLAMA_NUM_PARALLEL=4 OLLAMA_HOST='http://0.0.0.0:11434' eval $_ollama_serve"
    function ols_qwen_debug
        # FYI need new "TRACE" level OLLAMA_DEBUG=2 (previously =1 worked) to see prompts: https://github.com/ollama/ollama/pull/10650
        set cmd "OLLAMA_DEBUG=2 $_ollama_qwen"
        echo "$cmd\n" | bat -l fish
        eval $cmd
    end
    function ols_qwen
        set cmd "$_ollama_qwen"
        echo "$cmd\n" | bat -l fish
        eval $cmd
        # 4 requests @ 8k tokens each
        # TODO RoPE scaling params and/or impact on num_ctx?
        # model has n_ctx_training=32k but it is supposedly able to handle up to 128K tokens
    end

    abbr olshow "grc ollama show"
    abbr --set-cursor olshow_template "ollama show --template % | bat -l go" # go, jinja both seem ok
    abbr --set-cursor olshow_modelfile "ollama show --modelfile % | bat -l Dockerfile"
end

# TODO point cd => cd2?
function cd2
    # --description "cd improved"

    # if file passed, cd to dirname
    #   cd2 /Users/wes/repos/github/g0t4/dotfiles/foo.bar
    #     => cd /Users/wes/repos/github/g0t4/dotfiles
    # if path has spaces, don't need to quote it
    #   cd2 ~/Library/Application Support/iTerm2/Scripts
    #     => cd ~/Library/Application\ Support/iTerm2/Scripts
    # if path is relative to current user HOME dir then don't require ~ or $HOME prefix, try them for them:
    #   cd Library/Application Support/iTerm2/Scripts
    #     => cd ~/Library/Application\ Support/iTerm2/Scripts
    set path "$argv"
    if test -f $path
        # echo "File found: $path"
        set path (dirname $path)
    end
    # echo "cd2 $path"
    if test -d $path
        cd $path
    else if test -d $HOME/$path
        cd $HOME/$path
    else
        echo "Directory not found: $dir"
    end
end

# *** elgato profile sync ***
# NOTES
# - device names are stored in /Users/wesdemos/Library/Preferences/com.elgato.StreamDeck.plist
#   - just manually sync device names, mostly so I can make my streamdeck buttons to switch device
#   - otherwise doesn't matter if they differ given everything is a UUID (blessing and curse)
# - each profile is linked to device by UUID
#   bat **/manifest.json | jq .Device.UUID | sort | uniq -c  # count # per device UUID
#   bat **/manifest.json | jq .Name # show profile names
#

# allows `ls $elgato_wes` as needed
set elgato_wesdemos /Users/wesdemos/Library/Application\ Support/com.elgato.StreamDeck/ProfilesV2
set elgato_wes /Users/wes/Library/Application\ Support/com.elgato.StreamDeck/ProfilesV2
function elgato_diff_ProfilesV2
    icdiff -r $elgato_wesdemos $elgato_wes
end

function elgato_sync_ProfilesV2_dry_run
    elgato_sync_ProfilesV2 --dry-run
end

function elgato_sync_ProfilesV2
    # I detest manual export/import of profiles, one by one AND in bulk...
    # Can copy/sync ProfilesV2 dir verbatim and changes are picked up when restart stream deck app
    # FYI I also have smartsync profile saved on demos account

    # PRN kill stream deck
    # pkill -ilfa "Stream Deck" # when restart dest stream deck app it will ask to restore, say no... that is likely b/c it was running when I updated its profile files... so what for now, no issues

    set src /Users/wesdemos/Library/Application\ Support/com.elgato.StreamDeck/ProfilesV2
    set dest /Users/wes/Library/Application\ Support/com.elgato.StreamDeck/ # don't include ProfilesV2 else will make a nested copy ProfilesV2/ProfilesV2 (this path is dest for ProfilesV2 dir from wesdemos)

    # skip on --checksum (not mod-time/size compare) => small files so lets worry about contents
    # argv ... i.e. "--dry-run"
    rsync --checksum --recursive --itemize-changes --delete $src $dest $argv

    # ensure owned by wes on other end:
    sudo chown -R wes:staff /Users/wes/Library/Application\ Support/com.elgato.StreamDeck/ProfilesV2
    # same in reverse if I ever go wes=>demos
end

function elgato_kill_other_account_streamdeck
    # kill them before you change settings in current account's streamdeck, otherwise on quit the other one may overwrite new settings
    set other_user wes

    if test $USER = wes
        set other_user wesdemos
    else
        set other_user wes
    end

    sudo pkill -U $other_user -ilf "stream deck"
    sudo pkill -U $other_user -ilf streamdeck
    # just open other account's streamdeck next time you switch to it
end

# *** video editing wrappers ***

function quote_paths
    for path in $argv
        echo "'$path'"
    end
end

function video_editing_total_duration
    # wow I used my ask-openai CLI helper to generate this and it did and it works well (asked for first to get durations, then said split hours:mins:secs and sheesh it did it right using one lone command line with semicolon separators, I just split it out here... bravo this is not straightforward to do
    set totalSeconds 0
    for file in $argv
        set duration (ffmpeg -i $file 2>&1 | grep "Duration" | cut -d ' ' -f 4 | sed s/,//)
        set -l h (echo $duration | cut -d ':' -f1)
        set -l m (echo $duration | cut -d ':' -f2)
        set -l s (echo $duration | cut -d ':' -f3)
        set totalSeconds (math "$totalSeconds + ($h * 3600) + ($m * 60) + $s")
    end
    set -l hours (math "floor($totalSeconds / 3600)")
    set -l minutes (math "floor(($totalSeconds % 3600) / 60)")
    set -l seconds (math "$totalSeconds % 60")
    echo $hours:$minutes:$seconds

end
# *** thumbnails
abbr --add _150 --function abbr_thumbnail_check
function abbr_thumbnail_check
    set suffix "150px.png"
    set first_image (ls *.png | grep -v $suffix | head -1)
    set input_file (quote_paths "$first_image")
    set output_file (quote_paths "$(path basename --no-extension "$first_image").$suffix")
    echo "magick $input_file -resize 150 $output_file"
    echo "imgcat $output_file"
    # TODO apply quote_paths to more parts of similar abbrs
end

# *** #1 check audio ***
abbr --add _1 --function abbr_check
function abbr_check
    echo -n "video_editing_1_check_audio "
    abbr_videos_glob_for_current_dir
end
function abbr_videos_glob_for_current_dir
    # quite often I want to target all video files in current dir, so find those by different extensions and expand appropriately to match most use cases (priority order)
    if count *.mp4 >/dev/null
        echo -n "*.mp4"
    else if count *.m4v >/dev/null
        echo -n "*.m4v"
    else if count *.mkv >/dev/null
        echo -n "*.mkv"
    else if count *.mov >/dev/null
        echo -n "*.mov"
    end
    # default case don't add glob to match all video files
end
# FYI `veaud<TAB>` works in fish shell to complete this func:
function video_editing_1_check_audio
    # only arg would be file paths (i.e. from glob like *.mp4), btw dont need to pass any paths and it will do all *.mp4 in current dir
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_1_check_audio $paths"
end

# *** #2 convert 30fps ***
abbr --add _2 --function abbr_30fps
function abbr_30fps
    echo -n "video_editing_2_convert_30fps "
    abbr_videos_glob_for_current_dir
end
# FYI `veconv<TAB>` works in fish shell to complete this func:
function video_editing_2_convert_30fps
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_2_convert_30fps $paths"
end

function video_editing_extract_most_scene_change_thumbnails
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_extract_most_scene_change_thumbnails $paths"
end

abbr --add _mp4 --function abbr_mp4
function abbr_mp4
    # for now all mkv => mp4 helper func
    if test (ls *.mkv | count) -gt 0
        for mkv in *.mkv
            set output_file (string replace -r "\.mkv\$" ".mp4" "$mkv")
            if test -f "$output_file"
                continue
            end
            echo ffmpeg -i "'$mkv'" -c copy "'$output_file'"
        end
    end
end

function _video_editing_ffmpeg_file_list
    for p in $argv
        # use realpath to get absolute path, that way no issues w/ relative paths
        echo "file '$(realpath $p)'"
    end
end

function _get_first_file_extension
    # PRN move to top level fish function?
    echo $argv[1] | gsed 's/.*\.//'
end

function _get_first_file_dir
    realpath $(dirname $argv[1])
end

function _get_output_file_based_on_first_file
    # ! assumes -c copy so really only works on mkv/mp4 and similar types
    set output_name $argv[1] # i.e. combined.mp4 (first arg is output file name w/o path)
    set paths $argv[2..-1] # i.e. /Users/wes/foo/bar/baz.mp4 /Users/wes/foo/bar/baz.mp4

    set extension (_get_first_file_extension $paths[1])
    set path (_get_first_file_dir $paths[1])
    set output_file "$path/$output_name"
    echo $output_file
end

function _ffmpeg_concat
    set combined_file (_get_output_file_based_on_first_file combined.mp4 $argv)

    ffmpeg -f concat -safe 0 \
        -i (_video_editing_ffmpeg_file_list $argv | psub) \
        -c copy $combined_file
end

function _find_first_video_file_for_extension
    set ext $argv[1]
    set -f paths (fd --unrestricted --max-depth 1 --type f --extension $ext)
    if test (count $paths) -gt 0
        echo $paths[1]
        return
    end
    return 1
end

function _find_first_video_file_any_type
    # todo other types
    for ext in mp4 mkv mov
        set path (_find_first_video_file_for_extension $ext)
        if test "$path" != ""
            echo $path
            return
        end
    end
    return 1
end

abbr --add ffp --function _ffp
function _ffp
    echo -n "ffprobe -i "
    _find_first_video_file_any_type; or echo _
end

abbr --add ffi_range --set-cursor --function _ffi_trim
abbr --add ffi_trim --set-cursor --function _ffi_trim
function _ffi_trim
    set input (_find_first_video_file_any_type; or echo _)
    set output (path change-extension ".trimmed.mp4" $input)
    # echo -n "ffmpeg -i combined.shifted100ms.mp4 -ss 00:08:52 -to 00:09:22 -c:v copy -c:a copy trimmed-5m10s_to_5m40s.mp4"
    set duration (ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $input)

    echo -n "ffmpeg -i $input -ss 00:00 -to $duration"%" $output"
end

function _ffi_pass_middle_to_new_out
    # w/e is passed is inlined in the middle of the command
    set middle $argv
    set input (_find_first_video_file_any_type; or echo _)
    set output (path change-extension ".out.mp4" $input)
    echo -n "ffmpeg -i $input $middle $output"
end

abbr --add ffi --set-cursor --function _ffi_copy
abbr --add ffi_copy --set-cursor --function _ffi_copy
function _ffi_copy
    # careful w/ copy, it results in keyframe issues when trimming
    #  IIRC only want to use this when changing container... NOT when changing video
    _ffi_pass_middle_to_new_out "% -c copy"
end

abbr --add ffi_af --set-cursor --function _ffi_af
function _ffi_af
    _ffi_pass_middle_to_new_out "-af '%'"
end

abbr --add ffi_vf --set-cursor --function _ffi_vf
function _ffi_vf
    _ffi_pass_middle_to_new_out "-vf '%'"
end

abbr --add ffi_silencedetect --set-cursor --function _ffi_silencedetect
function _ffi_silencedetect
    set input (_find_first_video_file_any_type; or echo _)
    # remember % is cursor placeholder
    echo -n "ffmpeg -i $input -af silencedetect=noise=d=0.1:-30dB -f null -"
end

abbr --add ffi_astats --set-cursor --function _ffi_astats
function _ffi_astats
    set options ""
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end

abbr --add ffi_astats_per_frame --set-cursor --function _ffi_astats_per_frame
function _ffi_astats_per_frame
    set options "metadata=1:reset=1,ametadata=print:file=astats-per-frame.txt"
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end

abbr --add ffi_astats_overall --set-cursor --function _ffi_astats_overall
function _ffi_astats_overall
    # FTR =1 results in ONLY per OVERALL stats
    # ffmpeg -i record-silence-w-streamdeck-button-press-start-end.mkv -af astats=measure_overall=1 -f null -
    set options "measure_overall=1"
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end
abbr --add ffi_astats_perchannel --set-cursor --function _ffi_astats_perchannel
function _ffi_astats_perchannel
    # FTR =1 results in ONLY per channel showing (one set per channel in video/audio file)
    set options "measure_perchannel=1"
    set input (_find_first_video_file_any_type; or echo _) # copy pasta
    echo -n "ffmpeg -i $input -af astats=$options% -f null -" # copy pasta
end

# IDEAS (make reusable?)... maybe just have a lookup of these in a file somewhere and grep it?
#
# * trim, slow down and label:
# ffmpeg -ss 00:00:14.5 -to 00:00:14.9 -i approve-what-dialog-plugin-mixpre6.mov -an \
#   -filter_complex "[0:v]setpts=20.0*PTS,drawtext=text='20x slow down':fontcolor=white:fontsize=200:x=1500:y=2000:box=1:boxcolor=black@0.5[v]" \
#   -map "[v]" output.mp4
#

abbr --add _aio --function abbr_aio
function abbr_aio
    echo -n "video_editing_aio "
    abbr_videos_glob_for_current_dir
end

abbr shift_only 'for i in *.mkv; video_editing_just_shift_to_mp4_one_video $i; end'
function video_editing_just_shift_to_mp4_one_video
    # converts to mp4 + shifts by 100ms
    set video_file (realpath $argv[1])
    set output_file (path change-extension ".shifted100ms.mp4" "$video_file")
    if test -f "$output_file"
        echo "Skipping...file already exists: $output_file"
    else
        ffmpeg -i "$video_file" -itsoffset 0.1 -i "$video_file" -map 0:v -map 1:a -c:v copy -c:a aac "$output_file"
    end
end

function video_editing_aio
    set combined_file (_get_output_file_based_on_first_file combined.mp4 $argv)

    # based on: ffmpeg -i foo.mp4  -itsoffset 0.1 -i foo.mp4  -map 0:v -map 1:a -c:v copy -c:a aac foo-shifted100ms.mp4
    # PRN add ms param? right now 100 works for my setup OBS+mixpre6v2/mv7+logibrio
    set file_extension (_get_first_file_extension $combined_file)
    set output_file (string replace -r "\.$file_extension\$" ".shifted100ms.$file_extension" "$combined_file")
    if test -f "$output_file"
        echo "Skipping...file already exists: $output_file"
    else
        _ffmpeg_concat $argv # produces $combined_file

        # TODO change this to re-encode audio stream? to avoid some issues w/ start=NON-ZERO (ffprobe foo.mp4) output
        ffmpeg -i "$combined_file" -itsoffset 0.1 -i "$combined_file" -map 0:v -map 1:a -c:v copy -c:a aac "$output_file"
        trash $combined_file # be safe with rm, if it was wrong file I wanna have it be recoverable
    end

    # PRN skip if already exists?
    video_editing_gen_fcpxml $output_file
end

function video_editing_gen_fcpxml
    set video_file (realpath $argv[1])

    set -l base "$HOME/repos/github/g0t4/private-auto-edit-suggests"
    set python3 "$base/.venv/bin/python3"
    set script "$base/generate_fcpxml.py"
    $python3 $script $video_file
end

abbr --add _Xdb --regex '\d+db' --function abbr_db
function abbr_db
    set boost $argv[1] # i.e. 7db (do not need to have dB captial B... db is fine)

    # if only one video in current dir, select it
    # exclude previous boosted vides i.e. .7dB.m4v
    set video_files (ls *.{mp4,m4v,mov} | grep -vE "dB\.[a-z0-9]{3}\$")
    if test (count $video_files) -eq 1
        set video_file $video_files[1]
    end
    # TODO make a helper to deal with escaping, esp edge cases, have smth like:
    #   escape_for_echo_quoted ?
    set escaped_video_file (string replace "'" "\\'" $video_file)
    echo "video_editing_boost_audio_dB_by $boost '$escaped_video_file'"
end
#abbr 7db "video_editing_boost_audio_dB_by 7dB"

function video_editing_boost_audio_dB_by
    # usage:    video_editing_boost_audio_dB_by 7dB foo.mp4
    set boost_dB (string replace "db" "dB" $argv[1])
    set input_file (realpath $argv[2])
    set file_extension (_get_first_file_extension $input_file)
    set boosted_file (string replace -r "\.$file_extension\$" ".$boost_dB.$file_extension" "$input_file")
    # FYI I use sep audio detect to manually decide the boost, TODO maybe change to automate that? based on highest sample?
    ffmpeg -i "$input_file" -af "volume=$boost_dB" -c:v copy "$boosted_file"
end

if command -q npm

    # TODO REVISIT
    # suppress annoying warning for now
    # (node:76864) ExperimentalWarning: CommonJS module /opt/homebrew/lib/node_modules/npm/node_modules/debug/src/node.js is loading ES Module /opt/homebrew/lib/node_modules/npm/node_modules/supports-color/index.js using require().
    # Support for loading ES Module in require() is an experimental feature and might change at any time
    # (Use `node --trace-warnings ...` to show where the warning was created)
    export NODE_OPTIONS='--disable-warning=ExperimentalWarning'

    # PRN as I use and find how I wanna use aliases
    abbr npmi 'npm install'
    abbr npminit 'npm init -y'
    abbr npml 'npm list'
    abbr npmr 'npm run'
    abbr npmt 'npm test'
    abbr npma 'npm audit'
    abbr npmv 'npm version'
    abbr npms 'npm start'
    abbr npmo 'npm outdated'
    abbr npmun 'npm uninstall'
    abbr npmup 'npm update'

    abbr npxr 'npx run'

    # * brew install tree-sitter-cli
    # function tree-sitter --wraps tree-sitter
    #     # PRN did this work out?
    #     npx tree-sitter-cli $argv
    # end

    # FYI it's fine to get rid of these for a different tool to get the `ts` prefix
    abbr ts tree-sitter
    abbr tsg "tree-sitter generate"
    abbr tsb "tree-sitter build"
    abbr tsp "tree-sitter parse"
    abbr tst "tree-sitter test"
    abbr tsq "tree-sitter query"
    abbr tsh "tree-sitter highlight"
    abbr tsplayground "tree-sitter playground"

end

# TODO! add mechanism to discover duplicated abbrs => on-demand check?

abbr bm bitmaths # careful brew uses b* prefix
function bitmaths
    # FYI completions-eval-test-candidate

    # PRN show non-printable chars that make sense to show? i.e. \n \t etc yeah... \r
    echo -n "ascii: "
    python3 -c "print(hex($argv)[2:])" | xxd -r -p
    echo

    echo -n "bin: "
    python3 -c "print(bin($argv))"

    echo -n "hex: "
    python3 -c "print(hex($argv))"

    # echo -n "oct: "
    # python -c "print(oct($argv))" | bc --obase=8

    echo -n "dec: "
    python3 -c "print($argv)"

end

function pretty_size
    # FYI completions-eval-test-candidate
    # user passes in raw number like 1024  or 1024000 and this passes back 1KB, 1MB or w/e nearest size is
    set size $argv[1]
    if test (count $argv) -lt 1
        echo "Usage: size_in_bytes <size>"
        return 1
    end

    python3 -c "
import math;
if $size < 1024/2:
    print(f'{$size}B')
elif $size < 1024**2/2:
    print(f'{$size/1024:.2f}KB')
elif $size < 1024**3/2:
    print(f'{$size/1024**2:.2f}MB')
else:
    print(f'{$size/1024**3:.2f}GB')
"
end

# *** man page helpers
set man_cmd man
if $IS_MACOS
    # brew install man-db
    set man_cmd gman
    abbr man gman
end
abbr man_commands_1 "$man_cmd 1"
abbr man_syscalls_2 "$man_cmd 2"
abbr man_c_stdlib_3 "$man_cmd 3"
abbr man_kernel_interfaces_4 "$man_cmd 4"
abbr man_file_formats_5 "$man_cmd 5"
abbr man_misc_7 "$man_cmd 7"
abbr man_system_8 "$man_cmd 8"
abbr man_kernel_dev_9 "$man_cmd 9"
# list all pages in a section:
abbr --regex "manlist[0-9]" --function manlistX -- manlistX
function manlistX
    set section $(string replace manlist "" $argv[1])
    echo "$man_cmd -k . | grep '($section)'"
end
abbr man1 "$man_cmd 1"
abbr man2 "$man_cmd 2"
abbr man3 "$man_cmd 3"
abbr man4 "$man_cmd 4"
abbr man5 "$man_cmd 5"
abbr man6 "$man_cmd 6"
abbr man7 "$man_cmd 7"
abbr man7 "$man_cmd 8"
abbr man7 "$man_cmd 9"
#
# gman has --regex among other improvements
abbr mana "$man_cmd --all --regex" ## -a = all, -w = list path(s) open all matching pages
abbr mank apropos # man -k ~= apropos
abbr manf whatis # man -f == whatis
#
# * search all manpage text (preformatted files)
#   not in macOS's man
abbr man_grep "$man_cmd -K"
abbr man_grep_list "$man_cmd -w -K"
# i.e. gman -w -K autostash
# note -K is slow, hence why by default it starts showing pages it finds so you can look at them while it searches (presumably it continues searching in bg?)
#
abbr manw "$man_cmd --where --regex" # man -w == whereis for man pages, or map to whereis?
reminder_abbr man_list_all "$man_cmd --where --regex"
abbr manbash "$man_cmd $HOME/repos/github/g0t4/bash/doc/bash.1"
# use newest build of bash man page (at least don't use 3.2 from apple!)
abbr mbash "$man_cmd $HOME/repos/github/g0t4/bash/doc/bash.1"
#
# force pages in homebrew installed manpages to WIN
#  that way the manpage there for bash always takes precedence
#  and I NEVER see bash 3.2 from Apple's crap
#    that you cannot DELETE EITHER in /usr/share/man/man1/bash.1
# NOTE : colon on end means this is PREPENDED to std MANPATH (so I don't lose other pages, I just put these first)
#
# must use set b/c fish has special handling for PATH vars, so cannot just use trailing : like in bash
set -x MANPATH /opt/homebrew/share/man ""
# abbr manw "whereis" ???
# PRN whereis helpers?
# PRN apropos helpers?
# PRN whatis helpers?

# *** mitmproxy
abbr mitm mitmproxy
abbr mitml "mitmproxy --mode=local"
#
abbr mitmw mitmweb # web interface # PRN just set this to --mode=local?
abbr mitmwl "mitmweb --mode=local" # local mode
#
abbr mitmd "mitmdump --mode=local" # PRN just set this to --mode=local?
abbr mitmdl "mitmdump --mode=local" # local mode
#
# read flow files:
abbr mitmr "mitmproxy --no-server --rfile" # when reading, dont start server (that way can run separate instances with sep flow recordings)
#
# orphaned server:
# - sometimes mitmproxy server becomes orphaned (quit CLI doesn't stop it... so I need to find/stop it)
# - ignore if --no-server
abbr mitm_pgrep 'pgrep -ilf mitmproxy | grep -v "\--no-server" || true' # don't error if not found, avoid confusion
abbr mitm_kill 'pgrep -ilf mitmproxy | grep -v "\--no-server" | awk "{print $1}" | xargs sudo kill -9 || true'
#
# program specific
abbr mitmlc "mitmproxy --mode=local:'Visual Studio Code.app'" # capture just vscode (note not insiders)
abbr mitmlci "mitmproxy --mode=local:'Visual Studio Code - Insiders.app'"
abbr mitmlcurl "mitmproxy --mode=local:'curl'"
#
abbr mitms "mitmproxy --scripts" # pass script (i.e. python addons) # TODO do I use this?
abbr mitmsave "mitmproxy --save-stream-file" # # TODO do I use this?
#
# FYI possible options for config file:
#   PRN sync ~/.mitmproxy/config.yml via dotfiles
#   --anticomp # (default off) # TODO try to get servers to return uncompressed content, IIGC to make it easier to mod responses... FYI set this in config file not CLI arg
#   --console-layout {horizontal,single,vertical} # single (default) or split horiz/vertical an extra pane (ctrl+left/right).. just use `-` to switch layout on the fly for now
#       --no-console-layout-headers / --console-layout-headers   # PRN set in ~/.mitmproxy/config.yml
#
# Add when needed:
#   --map-remote PATTERN
#   --map-local PATTERN
#   --modify-body
#   --modify-headers
#
#   --intercept  # hard filter # maybe have option for this when using --save-stream-file since this is more likely to matter when saving
#   --view-filter  # soft filter (view only, actually captured still) # I would rather just do this with `f` in the running instance unless I wanna persist across restarts

function show_hex_rgb_color

    # TODO check if shell supports 24bit RGB true color, iTerm2 supports this (validated in my testing), but vscode doesn't (smth to do w/ color correction but don't care to fix that right now)

    #  show_hex_rgb_color "#000000" "000000"   # s/b all black (but vscode terminal isn't) => BEST INDICATOR of color corrections happening in vscode
    #  show_hex_rgb_color "#000000" "ff0000"   # s/b bright red
    #  show_hex_rgb_color "#000000" "00ff00"   # s/b bright green
    #  show_hex_rgb_color "#000000" "0000ff"   # s/b bright blue
    #  show_hex_rgb_color "#000000" "ffffff"   # s/b bright white on black
    #  show_hex_rgb_color "#ffffff" "000000"   # s/b black on white

    # usage: show_hex_rgb_color "#ff0000"  # show bgcolor only
    # usage: show_hex_rgb_color "#ff0000" "#000000" # show bgcolor and fgcolor
    set bgcolor $argv[1]
    set fgcolor $argv[2]

    # PRN handle other color formats as needed... or maybe make other methods for those

    # always have bgcolor:
    set bg_hex (string replace --regex -- "^#" "" $bgcolor) # ok if fails b/c no matches
    set bg_red (math "0x$(string sub $bg_hex --start 1 --length 2)")
    set bg_green (math "0x$(string sub $bg_hex --start 3 --length 2)")
    set bg_blue (math "0x$(string sub $bg_hex --start 5 --length 2)")

    if test -z $fgcolor
        # Print the background color in terminal, without any text
        printf "\e[48;2;%d;%d;%dm   %s   \e[0m\n" $bg_red $bg_green $bg_blue "           " # show spaces w/o text
    else
        set fg_hex (string replace --regex -- "^#" "" $fgcolor) # ok if fails b/c no matches
        set fg_red (math "0x$(string sub $fg_hex --start 1 --length 2)")
        set fg_green (math "0x$(string sub $fg_hex --start 3 --length 2)")
        set fg_blue (math "0x$(string sub $fg_hex --start 5 --length 2)")

        # Print the background color in terminal, with text
        printf "\e[38;2;%d;%d;%dm\e[48;2;%d;%d;%dm   %s   \e[0m\n" $fg_red $fg_green $fg_blue $bg_red $bg_green $bg_blue " text looks like " # show spaces w/o text
    end

end

# *** macOS screenshot helpers (for alfred file action => move here)

function _screenshots_trash_secondary_display
    # get rid of any second display screenshots (trash them for now, can always recover them if I really care later)
    for png in "$SCREENCAPS_DIR/"*"(2)"*.png
        # for doesn't fail if wildcard doesn't match anything: https://fishshell.com/docs/current/fish_for_bash_users.html#wildcards-globs
        trash $png
    end
end

function move_screenshots_from_last_x_hours
    set -l hours $argv[1]
    set -l dest_dir $argv[2]
    if test -z $hours
        echo "Usage: move_screenshots_from_last_x_hours <hours> <dest_dir>"
        return 1
    end
    if test -z $dest_dir
        echo "Usage: move_screenshots_from_last_x_hours <hours> <dest_dir>"
        return 1
    end

    # todo modeline to specify python in this embedded string/pseduofile
    echo "
from pathlib import Path
import os
import re
from datetime import datetime, timedelta

hours = $hours
dest_dir = Path(os.path.expanduser('$dest_dir'))
screencaps = Path(os.path.expanduser('$SCREENCAPS_DIR'))

formatted_str = '%Y-%m-%d at %H.%M.%S'
now = datetime.now()
cut_off = now - timedelta(hours=hours)
print('cutoff: ' , cut_off)

# example filename (varies by hostname):
#     hostfoo screencap 2024-09-27 at 00.26.43.png
# must match entire filename (full string contents)
date_time_pattern = r'.*screencap (\d\d\d\d-\d\d-\d\d at \d\d\.\d\d\.\d\d).*.png'

for png in screencaps.glob('*.png'):
    name = png.name
    matches = re.match(date_time_pattern, name)
    if not matches:
        continue
    time_str = matches.group(1)
    parsed_date = datetime.strptime(time_str, formatted_str)
    if cut_off > parsed_date:
        continue
    # png.rename(dest_dir / name)
    new_path = dest_dir / name
    print(f'moving {png} to {new_path}')
    png.rename(new_path)

" | python3

end

if command --query virsh
    # mostly convenience for the times I work intensely on VMs and other infra
    # ONLY the most prevalent commands I feel like suck w/ tab completion alone

    abbr virshl "virsh list"
    abbr virshla "virsh list --all"
    # abbr virshc "virsh console"

    abbr virshd "virsh define"
    abbr virshu "virsh undefine"
    abbr virshdx "virsh dumpxml"

    # leave these for when I spend more time and feel pain specifically, tab complete is actually working well mostly
    # abbr virshs "virsh start"
    # abbr virshdestory "virsh destroy"
    # abbr virshreboot "virsh reboot"
    # virsh vshresume "virsh resume"
    # virsh destroy - missing completions (completes files, needs --no-files and needs to complete domain names like `virsh start`)
    #    others: domstate, domstats, ... find and contribute other fixes (fish shell completions)

    abbr --set-cursor -- vshn 'virsh net-%' # complete the net subcommand, might be cool to hit TAB too automatically... could an abbreviation generate any sort of keyboard input?
    abbr virshnl "virsh net-list"
    # abbr virshndx "virsh net-dumpxml"
    abbr virshndl "virsh net-dhcp-leases" # mostly as reminder if Ctrl+S in virsh abbrs

end

if command --query cargo

    abbr cacl "cargo clean"
    abbr cab "cargo build"
    abbr car "cargo run"
    abbr catest "cargo test"
    abbr cabench "cargo bench" # reminder to investigate

    abbr caa "cargo add"
    abbr carm "cargo remove"
    abbr cau "cargo update"

    abbr canew "cargo new"
    abbr cainit "cargo init"
    abbr cas "cargo search"

end

function find_huge_files
    # find_huge_files +1M
    # find_huge_files +10M

    # FYI good question to ask with ask-openai just to validate helper is working
    # from deepseek-chat
    # find . -type f -size +100M -exec ls -lh {} \; | awk '{ print $9 ": " $5 }'

    set size +100M
    if test (count $argv) -gt 0
        set size $argv[1]
    end
    # BTW ~/.cache is a good dir to look for huge files (test command output)

    # find huge files and sort ascending: (deepseek-chat - V3 currently):
    find . -type f -size $size -exec ls -lh {} \; | awk '{ print $9 ": " $5 }' | sort -k2,2h
end

if command -q luarocks

    abbr lr luarocks
    abbr lrl luarocks list # global and local, for newest lua version
    abbr lrll luarocks list --local # only local
    abbr lrl1 luarocks list --lua-version=5.1 # nvim uses 5.1
    abbr lrl4 luarocks list --lua-version=5.4 # hammerspoon uses this + its the current release

    # abbr lrd luarocks doc # show docs for package

    abbr lri luarocks install
    abbr lrrm luarocks remove
    abbr lrs luarocks search
    abbr lrshow luarocks show

end

if command -q pacman

    # arch linux

    # FYI this could collide with my p* pipe abbrs (i.e. pgr => | grep -i), resolve it when that happesn
    abbr pm pacman

    # *** -S sync
    abbr --set-cursor pmss "sudo pacman -Ss '^%'" # (s)earch, name starts with
    abbr --set-cursor pm_search "sudo pacman -Ss '^%'" # reminder only
    # pacman -Ss regex => (s)earches desc too, can be noisy
    abbr pmsi "pacman -Si" # pkg (i)nfo
    abbr pm_info "pacman -Si"
    # pacman -Sl [repo] # list all pkgs in repo extra
    abbr pms "sudo pacman --noconfirm -S" # install (aka sync)
    abbr pm_install "sudo pacman --noconfirm -S" # reminder
    abbr pmsu "sudo pacman -Syu" # think [Sy]nc + [u]pgrade
    abbr pm_update "sudo pacman -Syu" # reminder is all

    # *** -R remove
    abbr pmr "sudo pacman -R --recursive" # -R remove, -s (--recursive) => also rm the deps that it has that are no longer needed
    abbr pm_uninstall "sudo pacman -R --recursive" # reminder

    # *** -Q query (local aka installed pkgs)
    abbr pmq "pacman -Q"
    abbr pm_listinstalled "pacman -Q" # training wheels reminder for what command b/c this is all truly confusing IMO, perhaps I should better wrap my mind around the commands?
    abbr pmqi "pacman -Qi" # pkg (i)nfo (probably easier to just use -Si for most pkgs unless install a local dev checkout)
    # search installed pkgs:
    abbr pmqs "pacman -Qs" # (s)earch ERE(regex) search installed pkgs (prolly just use `pacman -Q | grep -i`)
    abbr --set-cursor pmqg "pacman -Q | grep -i '%'" # I prefer grep, it's just easier to not need another tool specific option
    abbr --set-cursor pmqgs "pacman -Q | grep -i '^%'"
    #
    abbr pmql "pacman -Ql" # (l)ist files for pkg, can list multiple too (in which case first col is pkg name)
    # TODO any reason why I wouldn't just use -Fl always? perhaps if I custom build a pkg?
    abbr --set-cursor pmqlt "pacman -Qlq % | treeify_with_icons " # tree like list (-q == --quiet => show less info, in this case dont list pkg name column, just file paths)
    function treeify_with_icons
        # just a quick take on this... would like color too but treeify would need an option to support that too
        pacman -Ql procs | awk '{print $2}' | while read -l path
            if test -f "$path"
                set icon (lsd --icon=always "$path" 2>/dev/null | awk '{print $1}')
                echo "$path $icon"
            end
        end | treeify
    end

    abbr --set-cursor pm_listinstalledpkgfiles "pacman -Qlq % | treeify" # reminder
    #pacman -Qk fish # verify installed files
    abbr pmqo "pacman -Qo" # (o)wned by pkg
    abbr pm_whoownsfile "pacman -Qo"
    #pacman -Qo /path/to/file # find package for an installed file
    #pacman -Qo ip # owned by iproute2
    #
    # *** explicit / implicit installed pkgs
    abbr pmqe "pacman -Q --explicit" # list (e)xplicitly installed pkgs
    abbr pmqd "pacman -Q --deps" # list (e)xplicitly installed pkgs
    abbr pm_list_explicit_installs "pacman -Q --explict" # -e/--explicit
    abbr pm_list_implicit_installs_aka_deps "pacman -Q --deps" # -d/--deps
    #pacman -Qet # explicit installed packages (not required as deps of another package)
    #   IIUC, minimal set of packages to install to get back to where I am not
    #   IOTW -Qe == all packages I asked to install
    #        -Qet == if I asked for A and B, and B is a dep of A, then only A shows here (b/c A would trigger B's install)
    #pacman -Qdt # orphans (not explicitly installed, also no longer a dep of another package)
    abbr pm_list_upgrades "pacman -Q --upgrades"

    # *** Files database
    abbr pmf "pacman -F" # (f)ile => find file in remote packages
    # pacman -F /path/to/file # find file in remote package (i.e. not yet installed)
    # pacman -F ollama # or, w/o path => find what provides ollama command
    #
    # FYI for -Fl vs -Ql... mostly gonna be ok to use -Fl... but, if build a pkg by hand it might only be avail in locally installed packages
    abbr pmfl "pacman -Fl" # (l)ist files for (remote) pkg
    abbr --set-cursor pmflt "pacman -Flq % | treeify" # treeify list of files
    abbr --set-cursor pm_listremotepkgfiles "pacman -Flq % | treeify" # reminder
    abbr pmfy "sudo pacman -Fy" # reminder - download/s(y)nc fresh package databases

    # pactree reminder:
    #  -c/--color
    abbr pmtree "pactree -c"
    #
    abbr --regex 'pmtree\d+' --function __pmtreeX _pmtreeX
    function __pmtreeX
        string replace --regex '^pmtree' 'pactree -c -d' $argv
    end

    # TODOs (as I use and figure out what I want):
    # -R == --remove
    abbr prm "sudo pacman -R"
    # -U == --upgrade
    abbr pum "sudo pacman -U"

end

if command -q nvidia-smi
    # PRN if all these linux commands introduce too much overhead (i.e. in the command -q part)..
    #   then split them into a file and bail at top if not linux as a first check $IS_LINUX
    #  prefix == "nv" # seems fine, might overlap with neovim at some point?
    #  PRN alternative => use abbr --command nvidia-smi ... command level abbrs? or perhaps just need to fix completions which don't work even with fuc on man pages)
    abbr --set-cursor nv "nvidia-%" # kinda weird with space => dash but lets see how I feel as i use it and if it collides w/ anything else

    # TODO can I find a better source of copmletions?
    complete -c nvidia-container-cli --no-files -a "list info configure --help"

    # Basic commands
    abbr ns nvidia-smi
    abbr nsl "nvidia-smi -L" # List GPUs
    abbr nst "nvidia-smi -q -d temperature | bat -l yml" # not yaml, but close enough
    abbr nsu "nvidia-smi -q -d utilization | bat -l yml" # not yaml, but close enough
    abbr nstw "\$WATCH_COMMAND nvidia-smi -q -d temperature"
    abbr nsuw "\$WATCH_COMMAND nvidia-smi -q -d utilization"
    abbr nsm "nvidia-smi -q -d memory | bat -l yml" # Memory usage
    abbr nsmw "\$WATCH_COMMAND nvidia-smi -q -d memory"
    abbr nsp "nvidia-smi -q -d power | bat -l yml" # Power usage
    abbr nspm "\$WATCH_COMMAND -n 1 nvidia-smi -q -d power,memory,utilization" # Power and memory monitoring
    abbr nsf "nvidia-smi -q -d clock | bat -l yml" # Clock frequencies

    # Monitoring commands with loop
    abbr nsdmon "nvidia-smi dmon" # Device monitoring in scrolling format
    abbr nspmon "nvidia-smi pmon" # Process monitoring in scrolling format
    abbr nswatch "\$WATCH_COMMAND -n 1 nvidia-smi" # Basic monitoring with refresh

    # More specialized queries
    abbr nspids "nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv" # List processes using GPU
    abbr nstopo "nvidia-smi topo -m" # GPU topology matrix
    abbr nsnvlink "nvidia-smi nvlink -s" # NVLink status
    abbr nsgpu "nvidia-smi --query-gpu=gpu_name,gpu_bus_id,vbios_version --format=csv" # GPU details
    abbr nsall "nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv" # Detailed GPU info
end

function zedraw
    # zedraw 1.raw
    # for parsing mitm proxy e[x]ported raw (full req/response) files... and dumping the diff of input_excerpt vs output_excerpt to see the diff
    # FYI if headers change then line offsets will change for the request
    # todo can I just save a flow and extract matching requests and run through this so I can take a stream of predictions and review?
    set raw_file "$argv[1]"
    diff_two_commands "head -8 $raw_file | tail -1 | jq .input_excerpt -r" "tail -1 $raw_file | jq .output_excerpt -r"
end

function zedfull
    # show the request only
    set raw_file "$argv[1]"
    set json (head -8 $raw_file | tail -1 | jq) # not so useful to see the markdown embedded inside json fields so lets remove that

    log_ --blue "## .input_events"
    echo $json | jq -r .input_events
    log_ --blue "## .input_excerpt"
    echo $json | jq -r .input_excerpt
    log_ --blue "## .outline"
    echo $json | jq -r .outline

    set output_json (tail -1 $raw_file | jq)
    log_ --blue "## .output_excerpt"
    echo $output_json | jq -r .output_excerpt
end

# *** trash helpers

function trash
    if not command -q trash
        echo "trash not installed...  install or find workaround for your OS"
        return 1
    end

    if $IS_MACOS
        # -F => use finder to ensure `Put Back` works
        #   otherwise item is in trash but have to manually restore location
        for file in $argv
            if test -e $file
                command trash -F $file
            end
        end
    else if command -q trash
        command trash $argv
    else
        echo "TODO not implemented yet for your OS"
    end
end

# mostly for fun, also a good way to remember this exists :)
abbr fuc fish_update_completions

# *** ls* abbrs
if $IS_LINUX then

    # lscpue
    abbr lscpue "lscpu -e" # table like extended view
    abbr lscpuon "lscpu -e --online"
    abbr lscpuoff "lscpu -e --offline"

    # lspci
    abbr lspcit "lspci -tv" # tree, verbose
    abbr lspcik "lspci -k" # show kernel drivers (compatible and in use)
    #
    # -d [<vendor>]:[<device>][:<class>]		Show only devices with specified ID's
    # classes: https://admin.pci-ids.ucw.cz/read/PD/
    abbr lspciu "lspci -k -d ::00xx" # unclassified
    abbr lspcii "lspci -k -d ::01xx" # storage
    abbr lspcin "lspci -k -d ::02xx" # network
    abbr lspcig "lspci -k -d ::03xx" # graphics

    # lsblk # PRN

    # lshw
    abbr lshw "sudo lshw"
    abbr lshws "sudo lshw -sanitize"
    abbr lshwb "sudo lshw -businfo"
    abbr lshwcd "sudo lshw -class display"
    abbr lshwcn "sudo lshw -class network"
    abbr lshwcs "sudo lshw -class storage"

    # lsmod
    abbr --set-cursor lsmodg "sudo lsmod | grep -i '%'"

    # lsmem
    abbr lsmem "lsmem --output-all"

    # lspath
    # lstopo

    # lsusb
    abbr lsusb "lsusb -tv" # concise tree, a few more details
    abbr lsusbv "lsusb -v" # very detailed

    # dmesg
    abbr --set-cursor dmesgg "sudo dmesg | grep -i '%'"

end

if IS_MACOS

    # map some abbrs so I can get similar info on my mac to what I am used to using on linux/arch
    abbr lsusb "system_profiler SPUSBDataType"

end

# *** lsof
if command -q lsof

    # find app for a given port
    # sudo lsof -i :8080 (for now hardcode 8080 as reminder, once that's annoying I can remove it)
    abbr --set-cursor lsofi 'sudo lsof -i :8080%'
    abbr --set-cursor lsof_process_for_port 'sudo lsof -i :8080%' # reminder (so I can tab complete it when I inevitably forget the lsof options again)

    # files for a process:
    # TODO how to deal with multiple matches, I don't like using head but at least it is obvious in the expanded command so leave it for now
    abbr --set-cursor lsofp 'sudo lsof -p $(pgrep -if "%" | head -1)'
    abbr --set-cursor lsof_ports_for_process_pgrep 'sudo lsof -p $(pgrep -if "%" | head -1)' # reminder
    abbr --set-cursor lsofpi 'sudo lsof -p $(pgrep -if "%" | head -1) -a -i'
    abbr --set-cursor lsof_ports_for_pid 'sudo lsof -p % -a -i' # reminder
    # -p PID
    # -i == internet files (ports)
    # -a == AND constraints

    abbr --set-cursor lsofp_watch '$WATCH_COMMAND "sudo lsof -p \$(pgrep -if \"%\" | head -1)"'

end

# TODO wireshark
# start listening on intereface X and then with filter, i.e.:
#   !mdns and !db-lsp-disc and !nbns and tcp.port==62750

# TODO
# *** netstat
# if command -q netstat
# end

# *** ss
if command -q ss
    # -n # not resolve
    # -t -u # tcp+udp
    # -l # listening
    abbr ss_listening_ports "sudo ss -tunl" # listening are ommited by default
    abbr ss_notlistening_ports "sudo ss -tun"
    abbr ss_all_ports "sudo ss -tuna" # listening and not
end

# *** asciinema
abbr anr 'asciinema rec --overwrite test.cast' # PRN remake in fish:    abbr --set-cursor --add anr 'asciinema rec --overwrite %.cast'
abbr anp 'asciinema play'
abbr anu 'asciinema upload'
abbr anc 'asciinema cat'

function abbr_agg
    set -l cast_file *.cast
    if test -z "$cast_file"
        echo "no cast files"
        return
    end
    echo "agg --font-size 20 --font-family 'SauceCodePro Nerd Font' --theme 17181d,c7b168,555a6c,dc3d6f,9ed279,fae67f,469cd0,8b47e5,61d2b8,c229cf" $cast_file $cast_file.gif
end
abbr aggo --function abbr_agg

# NOTES about ROWS/COLUMNS:
# - check current size with: echo lines: $LINES cols: $COLUMNS
# ! *** prefer resize terminal before recording and asciinema will capture $ROWS $COLUMNS and just works on export then => dry run commands and see how they appear with constraints (ie upper left quarter of screen position window gives smaller window thats probably ideal for sharing a terminal gif recording)
#  *** OR `asciinema rec --rows X --cols Y...` works too though can be weird if smaller than actual terminal, esp if output would overflow the limits you place in --rows/--cols so best not to use this just set cols/rows by resizing window
#  IF YOU set agg's --cols/rows < actual cols/rows (in cast file) then you get a % and new lines in agg gif output

## agg
# PRN does agg support a config file? upon cursory inspection of repo I didn't see any documented nor in brief code review
#
# brew install agg
#
# config:
# --font-size 20+/--line-height
#   --font-dir/--font-family
#     mac:    --font-family 'SauceCodePro Nerd Font'
# --rows X / --cols Y
# --theme asciinema, dracula, monokai, solarized-dark, solarized-light, custom
# --speed 1.0
# --idle-time-limit 5.0 / --last-frame-delay 3.0
#   my terminal dark    --theme 17181d,c7b168,555a6c,dc3d6f,9ed279,fae67f,469cd0,8b47e5,61d2b8,c229cf
#
#
## asciicast2gif retired
#   https://github.com/asciinema/asciicast2gif
#   alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif'
#   successors:
#   - listed by asciicast2gif repo: https://github.com/asciinema/agg
#       nix! flake!
#   - copilot suggests: try ttygif?

abbr vllms "vllm serve"
# PRN some common args for vllm serve?
# abbr vllmsd "vllm serve --download-dir "
abbr vllmb "vllm bench"
abbr vllmc "vllm chat"
abbr vllmg "vllm complete"

# *** tail
abbr tailf 'tail -F'
abbr tailn 'tail -n 10'
abbr tailr 'tail -r' # reverse order
# *** frequently tailed files
abbr tt trash_n_tail
abbr ttp 'trash_n_tail ~/.local/share/nvim/ask-openai/ask-predictions.log' # nvim plugin
abbr ttls 'trash_n_tail ~/.local/share/ask-openai/language.server.log' # python LS
abbr ttnlsp 'trash_n_tail ~/.local/state/nvim/lsp.log' # nvim lsp logs
abbr tail_hardtime_logs 'cat ~/.local/state/nvim/hardtime.nvim.log | cut -c34- | sort | uniq -c | sort'
function trash_n_tail
    trash $argv
    tail -F $argv
end

# tail10<space> => tail -n 10
abbr taild --regex 'tail\d+' --function _taild
function _taild
    string replace tail 'tail -n ' $argv[1]
end

# do not use if command -q b/c yapf is often installed per venv
abbr -- yapfs "yapf --style-help"
abbr --command yapf -- sh --style-help

# * idea is to have rebuilders listed here
function rebuild_llama_cpp

    if not test -d ~/repos/github/ggml-org/llama.cpp
        echo llama.cpp not checked out, aborting...
        return 1
    end

    cd ~/repos/github/ggml-org/llama.cpp

    git fetch origin
    # show any commits reachable by `origin` (upstream) and not (^) readable by `^HEAD`
    if test -n "$(git rev-list origin ^HEAD)"
        # TODO address current branch vs its tracked? or is that implicit in this already?
        #    TLDR read up on git rev-list args
        log_ --red --bold "Upstream has new commits, pull if needed\n\n"
    end

    # warn user if any upstream commits, but don't stop build
    # b/c I might not want to build latest version!

    # if not git pull --rebase
    #     echo pull failed, aborting...
    #     return 1
    # end

    echo REBUILDING
    # trash build ? add step
    # LLAMA_CURL=on allows downloading models
    if $IS_MACOS
        # FYI metal is enabled by default on macOS
        #   https://github.com/ggml-org/llama.cpp/blob/3eac2093/docs/build.md#L111
        cmake -B build -DLLAMA_CURL=on
    else
        # just started to get failures today on build21 and build13... both had upgraded packages so maybe smth changed, i.e. using g++14 (is that newly released in arch repos?)
        #    type name is not   allowed
        # I found a similar issue on GH... guy said he fixed with setting env var vor NVCC_CCBIN... I did the same, albeit in my case g++-14, his case was g++-13
        #   and now the subsequent cmake to create build config works again!
        # https://github.com/ggml-org/llama.cpp/issues/10849
        export NVCC_CCBIN='/usr/bin/g++-14'
        # https://github.com/ggml-org/llama.cpp/blob/3eac2093/docs/build.md#L148
        cmake -B build -DGGML_CUDA=ON -DLLAMA_CURL=on
    end

    # PRN enable cuda if present on machine or based on machine name
    cmake --build build --config Release -- -j (nproc)

end

# * test inference infra

#  simple convenience funcs so I don't have to hunt down something special
function test_vllm_v1_completions_streaming
    echo '{
      "prompt": "Please show me the tower of hanoi in lua",
      "max_tokens": 200,
      "temperature": 0.0,
      "stream": true
    }' | http localhost:8000/v1/completions
end
function test_vllm_v1_completions
    echo '{
      "prompt": "Please show me the tower of hanoi in lua",
      "max_tokens": 200,
      "temperature": 0.0
    }' | http localhost:8000/v1/completions
end
function test_vllm_v1_completions_raw_text
    # if want a crude check of validity of generated text
    test_vllm_v1_completions | jq .choices[0].text -r
end

if command -q wscat
    abbr wscatc 'wscat --connect -L --slash --show-ping-pong ws://localhost:8000'
    abbr wscatl 'wscat --listen 8000' # run an echo server locally
    #  FYI --show-ping-pong ONLY applies when using -c/--connect (the client)
    abbr wscat_echo_org 'wscat --connect -L --slash --show-ping-pong ws://echo.websocket.org'
end

# * uname
abbr una "uname -a"

if command -q hs
    # hammerspoon

    # hs command usage:
    # hs -c foo -c bar # run foo => then bar
    # hs [-i]  # REPL
    # echo script | hs # run script

    # * interactive REPL mode:
    # -i is default on, so don't need to pass it
    # let this annoy me as a reminder that it exists (type hs<space> expands to hs -C)
    abbr hs "hs -C" # interactive, is default mode
    abbr hs_interactive "hs -C" # mostly a reminder that interactive mode exists!
    abbr hsq "hs -q"
    #
    # REPL + mirroring?
    # mirroring hs cmd/repl => hs console
    abbr hs_clone_from_console "hs -C"
    # mirroring from console => hs cmd/repl
    abbr hs_clone_to_console "hs -P"
    # FYI -C/-P won't work with my hack to suppress the hard coded print("-- Loading extension: "..key)
    #   which is baked into hammerspoon's code:
    #     https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/_coresetup/_coresetup.lua#L456
    #   so my override (which temporarily overrides print, probably means -C/-P patches my print override
    #   so when I put the original print back then the override is gone!

    # running commands
    abbr hsc "hs -c" # run a command
    abbr hscq "hs -c -q" # quiet mode (only errors and final result)

end

if command -q ctags
    abbr ct ctags
    abbr ctags_stdout_only_lua "ctags --languages=lua -f -"
    abbr --set-cursor ctl ctags --list-%
    abbr ctle ctags --list-excludes
    abbr ctll ctags --list-languages
    abbr ctlf ctags --list-fields
    abbr ctlx ctags --list-extras
    abbr ctags_stdout ctags -f -
    # helpers to review what was swept up (or not)
    abbr ctags_list_not_files "cat tags  | sort | uniq | grep -v -E '\.(zsh|lua|py|rs|c|md|json|vim|plist|js|ps1)' | bat -l csv"

end

# lets see how I feel about awk being auto '' quoted... I can change later if this upsets me
#   i.e. if I find myself often wanting to set args -F ... then this might be annoying
# abbr --set-cursor awk "awk '/%/ { print }'"
#
# abbr awk4 "awk '{print $4}'"
abbr --add _awkd --regex 'awk\d+' --function _abbr_expand_awk
function _abbr_expand_awk
    string replace --regex "(\d+)" " '{print \\\$\$1}'" $argv[1]
end

# PRN add back if actually useful... for now don't need a-zA-Z for the separator!
# # abbr awk4_ where _ is any character you want
# abbr --add _awkd_char --regex 'awk\d+([a-zA-Z])' --function _abbr_expand_awk_char
# function _abbr_expand_awk_char
#     string replace --regex "(\d+)([a-zA-Z])" " \-F\$2 '{print \\\$\$1}'" $argv[1]
# end

# awk4t
abbr --add _awk_tab --regex 'awk\d+t' --function _abbr_expand_awk_tab
function _abbr_expand_awk_tab
    string replace --regex "(\d+)t" " \-F'\t' '{print \\\$\$1}'" $argv[1]
end

# awk4,
abbr --add _awk_comma --regex 'awk\d+,' --function _abbr_expand_awk_comma
function _abbr_expand_awk_comma
    string replace --regex "(\d+)," " \-F, '{print \\\$\$1}'" $argv[1]
end

# awk4p (as in pipe | delimiter)
#  cannot type | in an abbr b/c its a command delimiter
abbr --add _awk_pipe --regex 'awk\d+p' --function _abbr_expand_awk_pipe
function _abbr_expand_awk_pipe
    string replace --regex "(\d+)p" " \-F'\|' '{print \\\$\$1}'" $argv[1]
end

# * token counting
function count_tokens_qwen25_coder
    # usage:
    # cat foo.txt | count_tokens_qwen25_coder
    $WES_DOTFILES/.venv/bin/python3 -c "
import sys
from transformers import AutoTokenizer
tokenizer = AutoTokenizer.from_pretrained('Qwen/Qwen2.5-Coder-7B-Instruct')
text = sys.stdin.read()
print(len(tokenizer.encode(text)))
"
end

# * comm(on) command
#  honestly this makes me wanna write some of my own commands that aren't abbreviated for 32KB tech from 70 years ago
#  fish like fashion: `lines intersect` `lines union` `lines left-only` `lines right-only`
#     maybe even `lines diff` should be here too? maybe not
abbr common comm # why didn't they just call it co
# FYI -1 = left only, -2 = both, -3 = right only
abbr common_left_only comm -2 -3
abbr common_right_only comm -1 -2
abbr common_both comm -1 -3
abbr intersection comm -1 -3

# * screencapture + tesseract to OCR
function screencapture_ocr
    # tmp dir first
    set tmp_dir (mktemp -d)
    # echo $tmp_dir

    set img_file "$tmp_dir/cap.png"
    # F'in tesseract wants to add .txt to the file name... FUUUU seriously... so just do this here
    set text_file "$tmp_dir/ocr"

    # Let user select area for screenshot
    screencapture -s -x "$img_file"

    # OCR
    tesseract "$img_file" "$text_file" >/dev/null 2>&1

    cat "$text_file.txt" # dump for interactive terminals
    cat "$text_file.txt" | pbcopy # and copy to clipboard

    trash $tmp_dir
end

function use_nvim_from_source

    set repo "$HOME/repos/github/neovim/neovim"

    export PATH="$repo/build/bin:$PATH" # nvim source dir
    export MANPATH="$repo/build/share/man:$MANPATH" # man pages for neovim
    export VIMRUNTIME="$repo/runtime" # so we have all the vim scripts

end

# * rsync
# key args...
# --dry-run/-n
#   --list-only (implied if no destination dir):
abbr rsync_list_only_source_files rsync --recursive --dry-run .
# --verbose (-v),
# --archive (-a == -Dgloprt)
#   --group/-g - set group on dest
#   --links/-l - tx symbolic links
#   --owner/-o - set owner on dest
#   -p - set perms on dest
#   -r - --recursive/-r
#   -t - set mod-times
# --dirs/-d (instead of --recursive, copy dirs... need trailing slash/ or . to copy dir contents too)
# --checksum (-c) - compare checksum, instead of quick check (file size / mod-time)
# --compress/-z - during tx
# --delete (with -r only)
# --exclude/--include
# --extended-attributes - macos specific
# --force
# --fuzzy/-y - look for files that might be the same
# --ignore-existing
#   --ingnore-non-existing/--existing
# --quiet/-q - only print errors
# --progress - print periodic updates
#   --stats - at end
#
# FYI! always use trailing slash... so its always contents of foo/ to contents bar/ dir
#
# most or all of my abbrs should have --dry-run at the end, I can easily remove it when ready
# FYI if copied smth already with say macos... use --recurisve (instead of --archive which also has --recursive) ... that way you only compare the file contents and not owner/group/mod-time/perms too
# quick = default size/mod-time check
abbr rsync_quick rsync --archive --delete --progress --stats --dry-run
abbr rsync_quick_dry_run rsync --archive --delete --itemize-changes --dry-run
# checksum = compare contents
abbr rsync_checksum rsync --archive --delete --checksum --progress --stats --dry-run
abbr rsync_checksum_dry_run rsync --archive --delete --checksum --itemize-changes --stats --dry-run
# FYI add _dry_run b/c w/ dry-run I want --itemize-changes output... whereas w/ a real copy I want --progress...
#   that said, all have --dry-run just to be safe on end

# * history command
abbr hist "history | bat -l fish --color always | less -F"

# * string abbrs
#
# pipe => string split
# FYI won't tab complete, except in command position... so just drop | and see if I like that way?
abbr strs_lines "string split '\n'"
abbr strs_comma "string split ','"
abbr strs_space "string split ' '"
abbr strs_tab "string split '\t'"
abbr strs_colon "string split ':'"
abbr strs_pipe "string split '|'"
#
abbr strjoin_lines "string join '\n'"
#
#
# TODO other string * abbrs

# * BASH

abbr b bash
#
# FYI these alternate bash invocations are mostly for test/demo purposes
#   only material diff is the env vars passed
#   99% of the time it's ok to just use `bash` from fish shell... and inherit the env
#     also ok to not use --login on these too as my startup files don't differentiate
#
abbr bash_full_rc 'bash --rcfile "$WES_DOTFILES/bash/full.bashrc.sh"'
abbr bash_env_no_inherit "env -i HOME=$HOME \$(which bash)"
abbr bash_env_no_inherit_no_startup "env -i HOME=$HOME \$(which bash) --noprofile --norc"
function bash_env_iterm_inherit_without_path
    # restrict env vars inherited..
    # mostly to ensure my bashrc can run independent of parent fish shell's env vars
    # skip PATH so I know its setup consistently
    env -i \
        LANG="$LANG" \
        TERM="$TERM" \
        COLORTERM="$COLORTERM" \
        SHELL="$SHELL" \
        USER="$USER" \
        LOGNAME="$LOGNAME" \
        TMPDIR="$TMPDIR" \
        HOME="$HOME" \
        SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
        DISPLAY="$DISPLAY" \
        TERM_PROGRAM="$TERM_PROGRAM" \
        TERM_PROGRAM_VERSION="$TERM_PROGRAM_VERSION" \
        LC_TERMINAL="$LC_TERMINAL" \
        LC_TERMINAL_VERSION="$LC_TERMINAL_VERSION" \
        __CF_USER_TEXT_ENCODING="$__CF_USER_TEXT_ENCODING" \
        "$(which bash)" \
        $argv
end

abbr bash_abbr_tests "ABBR_TESTS=1 bash"
abbr bash_abbr_tests_debug "ABBR_TESTS=1 ABBR_DEBUG=1 bash"
#
abbr bash_startup_trace 'PS4="+ \${BASH_SOURCE}:\${LINENO}: " bash -x -l'

# * strace
# --trace=syscall
# --trace=/regex_syscall
# categories
abbr --set-cursor strace_process "strace -f -e trace=process bash"
abbr --set-cursor strace_file "strace -f -e trace=file bash"
abbr --set-cursor strace_network "strace -f -e trace=network bash"
abbr --set-cursor strace_signal "strace -f -e trace=signal bash"
abbr --set-cursor strace_desc "strace -f -e trace=desc bash"
abbr --set-cursor strace_ipc "strace -f -e trace=ipc bash"
abbr --set-cursor strace_memory "strace -f -e trace=memory bash"
abbr --set-cursor strace_all "strace -f -e trace=all bash"
# fds=
abbr --set-cursor strace_fds "strace -f -e fds=0,1,2 bash"
abbr --set-cursor strace_fdSTDIN "strace -f -e fds=0 bash"
abbr --set-cursor strace_fdSTDOUT "strace -f -e fds=1 bash"
abbr --set-cursor strace_fdSTDERR "strace -f -e fds=2 bash"
# use fdSTDERR to see where the shell writes the prompt!
#
# syscalls / regex
abbr --set-cursor strace_open "strace -f -e trace=/open bash"
abbr --set-cursor strace_read "strace -f -e trace=/read bash"
abbr --set-cursor strace_write "strace -f -e trace=/write bash"
#
# count / summary
abbr --set-cursor stracec "strace -c -e trace=all sleep 1"
abbr --set-cursor straceC "strace -C -e trace=all sleep 1"

# *** fish
abbr --set-cursor -- fishc "fish -c '%'"
abbr pPATH 'for p in $PATH; echo $p; end'

# *** openai completions helpers

# not just psse b/c I can't get tab completion of --position=anywhere abbreviations
#  strip until first { .. that way any prefix (data: and/or log messages) are stripped at front of line
#    that means I can double click a line in llama-server logs and copy all of it and jq just works!
set --local sse_jq 'string replace --regex "[^{]*" "" | jq'
# pipe alone (not from clippy)
abbr --position=anywhere -- psse "| $sse_jq"
abbr --position=anywhere -- pssec "| $sse_jq --compact-output"
# pbpaste then pipe
abbr -- pbsse "pbpaste | $sse_jq"
abbr -- pbssec "pbpaste | $sse_jq --compact-output"
# grab __verbose.prompt (llama-server uses this)
abbr -- pbsse_verbose_prompt "pbpaste | $sse_jq '.__verbose.prompt' -r"
# TODO I really need to write my own script (python?) and have this do detection on the prompt value and just auto suggest adding treesitter on the end
#    and add support for other formats and coloring them
abbr -- pbsse_verbose_prompt_harmony "pbpaste | $sse_jq '.__verbose.prompt' -r | tree-sitter highlight --scope source.harmony"
abbr -- pbsse_verbose_content "pbpaste | $sse_jq '.__verbose.content' -r" # this is the RAW RESPONSE from the model
abbr -- pbsse_verbose_raw_response "pbpaste | $sse_jq '.__verbose.content' -r" # this is the RAW RESPONSE from the model
abbr -- pbsse1 "pbpaste | $sse_jq > input-messages.json"
abbr -- pbsse2 "pbpaste | $sse_jq > input-rendered-prompt.json"
abbr -- pbsse3 "pbpaste | $sse_jq > output-parsed-message.json"
abbr -- pbssethread 'ask_thread_reviewer (pbpaste | string replace --regex "[^{]*" "" | psub)'

#
# * pbsse4 (raw prompt)
# FYI sse4 is not an sse but the naming convention helps me quickly remember each of these! (first 3 are SSEs)
abbr -- pbsse4 "pbpaste | string replace --regex '^\w\w\w \d\d \d\d:\d\d:\d\d \w+ llama-server\[\d+\]: ' '' | string replace 'Parsing input with format GPT-OSS: ' '' > output-raw.harmony"
# strip this from all lines:
#   Dec 09 18:11:03 build21 llama-server[3344]:
# then first line also has:
#   Parsing input with format GPT-OSS:
#
# FYI I assume line breaks in logs are from literal line breaks in the response that s/b preserved
#  TODO setup to work with other prompt types... not just GPT-OSS/harmony... i.e. Qwen3
#  TODO and setup to rename file based on prompt format (if applicable?) .. at least not call it .harmony :)

# ? --join-output

# * date
abbr date_s "date +%s"
reminder_abbr date_unixtime "date +%s" # reminder abbr

## general cd
abbr cdr 'cd "$(_repo_root)"' # * favorite

## open
abbr orr 'open "$(_repo_root)"' # can't use `or` in fish :)
abbr oh 'open .'

####### vscode aliases:
abbr ch 'code .' # * favorite
abbr cih 'code-insiders .'
abbr cr 'code "$(_repo_root)"' # * favorite
abbr cir 'code-insiders "$(_repo_root)"'
## adv
abbr cie 'code --inspect-extensions=9229 .' # attach then with devtools, mostly adding this so I remember it
abbr cieb 'code --inspect-brk-extensions=9229 .' # attach, set breakpoints, then run!

#### zed
abbr zh 'zed .'
abbr zr 'zed "$(_repo_root)"'
abbr zph 'zed-preview .'
abbr zpr 'zed-preview "$(_repo_root)"'

### cursor
abbr cs 'cursor .'
abbr csr 'cursor "$(_repo_root)"'

# z
abbr zx 'z -x'

# tar:
abbr tarx 'tar -xf' # e(x)tract
abbr tarx_stdout 'tar -O -xf' # e(x)tract to std(O)ut
abbr tart 'tar -tf' # lis(t) / (t)est
abbr tarc 'tar --xz -cf' # create xz (todo use set-position to put cursor in name that already has .txz extension)
abbr tarcg 'tar --gzip -cf' # create gzip (todo use set-position to put cursor in name that already has .tgz extension)
abbr tarcb 'tar --bzip2 -cf' # create bzip2 (todo use set-position to put cursor in name that already has .tbz2 extension)

# *** jar (zip)
abbr jarx 'jar -xf' # e(x)tract
abbr jart 'jar -tf' # lis(t) / (t)est
abbr --set-cursor -- jartree 'jar -tf %.jar | treeify'
abbr jaru 'jar -uf' # u(n)pack
abbr jarc 'jar -cf' # create
# TODO more based on jar/zip/unzip (FYI bsdtar supports zip, not gnu tar)

# *** unzip
abbr unzipx_stdout 'unzip -p' # e(x)tract to std(O)ut
abbr unzipl 'unzip -l' # lis(t) / (t)est
# TODO flesh out later, FYI use zip for create equivalaents
#   PRN make all these abbrs via zip and unzip? same set and just use respective command based on action? (unlike tar which has one command for all ops)

# *** java abbrs
abbr java19 'export PATH="$(/usr/libexec/java_home -v 19)/bin:$PATH"'

# *** jcmd
abbr jcmd_screenpal "jcmd \$(screenpal_pid) " # get PID with `jcmd` or `jps` or `ps aux | grep ScreenPal`

# *** mvn
abbr mvnls 'mvn dependenices:list'
abbr mvntree 'mvn dependenices:tree'
abbr mvnc 'mvn compile'
abbr mvnp 'mvn package'
abbr mvnt 'mvn test'

# *** screenpal
abbr spkill "pkill -ilf screenpal"
# abbr spkilltray "pkill -ilf 'screenpal tray'"
abbr spkilltray "echo disable tray app in partner properties file"
abbr splog "cat ~/Library/ScreenPal-v3/app-0.log"
abbr splogrm "rm ~/Library/ScreenPal-v3/app-0.log"
# PRN tray-0.log ... but don't need it right now
function screenpal_pid
    set --local pid (jcmd | grep ScreenPal | head -1 | cut -d' ' -f1)
    echo $pid
end

# *** streamdeck icon helpers

function streamdeck_svg2png_padded_square_only
    # FTR this was desigend initially to work with screenpal icons (svgs) extracted from JARs which are square to start

    if not test -d drop-originals-svgs-here
        echo "CRAP: missing dir 'drop-originals-svgs-here', created it for you, now put your SVGs in it"
        mkdir -p drop-originals-svgs-here
        return 1
    end

    mkdir -p final tmp_pngs

    for image in drop-originals-svgs-here/*.svg
        # * make 96px wide PNG (height is scaled)
        set base (basename $image .svg)
        set new_png "tmp_pngs/$base.png"
        svg2png --width=96 $image $new_png

        # * make 120px PNG with padding around the 96px PNG
        set new_padded "final/$base.padded.png"
        set width 120
        magick "$new_png" -gravity center -background transparent -extent 120x120 "$new_padded"
    end
end
