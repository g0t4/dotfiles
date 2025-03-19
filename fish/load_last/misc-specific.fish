
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
# bind shift-delete kill-word # shift+del to kill forward a word (otherwise its esc+d only), I have a habit of using this (not sure why, probably an old keymapping in zsh or?)
#  dont wanna clobber new shift-delete in autosuggests... and I don't think I used shift-delete often for delete forward anyways
function on_change_show_verbose_prompt --on-variable show_verbose_prompt
    commandline --function repaint
end
function toggle_show_verbose_prompt
    if not set --query show_verbose_prompt
        set --universal show_verbose_prompt "yes"
    else
        set --universal --erase show_verbose_prompt
    end
    # commandline --function repaint
end
bind f4 toggle_show_verbose_prompt




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

    abbr sc 'sudo systemctl'
    abbr scu 'sudo systemctl --user'

    abbr scm 'man systemd.index' # great entrypoint to systemd man pages

    abbr scs 'sudo systemctl status'
    abbr scstop 'sudo systemctl stop'
    abbr scstart 'sudo systemctl start'
    abbr screstart 'sudo systemctl restart'
    abbr scenable 'sudo systemctl enable'
    abbr scdisable 'sudo systemctl disable'
    abbr sck 'sudo systemctl kill' # PRN --signal=SIGKILL?

    abbr sccat 'sudo systemctl cat'
    abbr scedit 'sudo systemctl edit'
    abbr screvert 'sudo systemctl revert'
    abbr scshow 'sudo systemctl show'

    abbr scls 'sudo systemctl list-units'
    abbr sclsf 'sudo systemctl list-unit-files'
    abbr sclss 'sudo systemctl list-sockets'
    abbr sclsd 'sudo systemctl list-dependencies'

    abbr jc 'sudo journalctl -u'
    abbr jcu 'sudo journalctl --user-unit'

    abbr jcb 'sudo journalctl --boot -u' # current boot
    abbr jcb1 'sudo journalctl --boot=-1 -u' # previous boot
    abbr jcboots 'sudo journalctl --list-boots'

    abbr jcs 'sudo journalctl --since "1min ago" -u'
    abbr jck 'sudo journalctl -k' # kernel/dmesg

    abbr jcf 'sudo journalctl --follow -u'
    abbr jcfa 'sudo journalctl --follow --no-tail -u' # all lines + follow

    # WIP - figure out what I want for cleanup, when testing I often wanna just clear all logs and try some activity to simplify looking at journalctl history, hence jcnuke
    abbr jcnuke 'sudo journalctl --rotate --vacuum-time=1s' # ~effectively rotate (archive all active journal files) then nuke (all archived journal files)
    abbr jcr 'sudo journalctl --rotate' # rotate (archive) all active journal files (new journal files going forward)
    abbr jcvs 'sudo journalctl --vacuum-size=100M' # vacuum logs to keep total size under 100M
    abbr jcdu 'sudo journalctl --disk-usage' # total disk usage
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
    abbr ctripull --set-cursor='!' 'sudo ctr image pull docker.io/library/!'
    abbr ctrirm --set-cursor='!' 'sudo ctr image rm docker.io/library/!'

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
    abbr kgcj 'kubectl get cronjobs'
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
    abbr kgj 'kubectl get jobs'
    abbr kgno 'kubectl get nodes' # alias: no
    abbr kgpv 'kubectl get persistentvolumes' # alias: pv
    abbr kgpvc 'kubectl get persistentvolumeclaims' # alias: pvc
    abbr kgrb 'kubectl get rolebindings -o wide' # wide shows role and subject (user/group/sa) so I absolutely want this by default
    abbr kgro 'kubectl get roles'
    abbr kgrs 'kubectl get replicasets' # alias: rs
    abbr kgs 'kubectl get svc'
    abbr kgsa 'kubectl get serviceaccounts' # alias: sa
    abbr kgsc 'kubectl get storageclasses' # alias: sc
    abbr kgsec 'kubectl get secrets'
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
    abbr ktp 'kubectl top pod --all-namespaces'
    abbr ktn 'kubectl top node'
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
    # abbr --set-cursor='!' -- kxs 'kubectl config set-context --current --namespace=!' # kxsn if want more set abbr's
    # abbr --set-cursor='!' -- kns 'kubectl config set-context --current --namespace=!' # this is easier to remember BUT does not fit into kx abbr "namespacing" (pun intended)
    function kns
        # use kns so I can add namespace completion (below) => PRN could attempt fix to kubectl completion (doesn't work on --namespace flag)
        kubectl config set-context --current --namespace $argv
    end
    complete -c kns -a '(kubectl get namespace -o custom-columns=:metadata.name)' --no-files
    #
    abbr kxu 'kubectl config use-context'
    abbr kxls 'kubectl config get-contexts'
    abbr kxv 'kubectl config view'

end

if command -q dig

    # always use grc w/ dig:
    # TODO only if interactive shell? if so also do that for kubectl above (and others)
    # alias dig "grc dig"
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
    abbr --set-cursor="!" -- hgk 'helm get manifest ! | kubectl get -f -'
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
    abbr --set-cursor='!' -- hic "helm show chart ! | yq"
    #    crds        show the chart's CRDs
    #    readme      show the chart's README
    abbr --set-cursor='!' -- hir "helm show readme ! | bat -l md"
    #    values      show the chart's values
    abbr --set-cursor='!' -- hiv "helm show values ! | yq"
    #
    # status      display the status of the named release
    abbr hst 'helm status'
    #
    # template    locally render templates
    # abbr --set-cursor='!' -- ht 'helm template ! | yq' # repo/chart-name
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
#
# shell variables names and values
abbr vls "set | bat --language ini -p"
abbr vgr "set | grep -i "
#
abbr --add agr --set-cursor='!' "abbr | grep -i '!'" # i.e. to find `git status` aliases
abbr --add agrs --set-cursor='!' "abbr | grep -i '\b!'" # i.e. for finding aliases that start with `dc` or `gs` etc => useful when creating new aliases to find a "namespace" that is free

# *** bind workaround ***
# FYI known bug with new --set-cursor abbr
#    https://github.com/fish-shell/fish-shell/issues/9730
# bind --preset ' ' self-insert expand-abbr
bind ' ' self-insert expand-abbr # self-insert first since it doesn't matter before/after on " " and then --set-cursor abbr's work with ' ' trigger
# rest work with vanilla abbrs but not --set-cursor abbrs:
# bind --preset ';' self-insert expand-abbr
bind ';' expand-abbr self-insert
# bind --preset '|' self-insert expand-abbr
bind '|' expand-abbr self-insert
# bind --preset '&' self-insert expand-abbr
bind '&' expand-abbr self-insert
# bind --preset '>' self-insert expand-abbr
bind '>' expand-abbr self-insert
# bind --preset '<' self-insert expand-abbr
bind '<' expand-abbr self-insert
# bind --preset ')' self-insert expand-abbr

# *** binds (consolidate here) ***
# FYI fish4 OOB has:
#   alt-. history-token-search-backward
#   alt-up history-token-search-backward
#   alt-down history-token-search-forward
#
#   if I wanna add back Esacpe,dot then:
#     bind escape,. history-token-search-backward
#   for now lets just remind myself and see if I can pick up alt up/down quickly... b/c I always blow past tokens and normally can't reverse so I wanna use up/down to reverse easily too!
bind escape,. "commandline --append 'alt-up'; commandline --cursor 10000" # move cursor to end too (so can ctrl-w to wipe out inserted reminder token)

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
# TODO add more in time as I encounter scenarios
#
# NOTES:
# - keep non-format options on end of cmd to easily toggle:
# - user:10 - limits to 10 chars (+ indicates ...) (:X ubuntu yes, macos no):
#       ps -o "user:5,pid,pcpu,pmem,vsz,rss,tty,stat,start,time,comm" -ax
#
# *** pstree
# pstreeX => pstree -l X
abbr --add _pstreeX --regex "pstree\d+" --function pstreeX
function pstreeX
    string replace pstree 'pstree -l' $argv
end
abbr pstrees --set-cursor='!' 'pstree -s "!"' # ***! NEW FAVORITE, shows all matching parents/descendants (IIUC)
abbr pstreep 'pstree -p' # parents/descendants of PID, without -p then its just descendants
abbr pstreeU 'pstree -U' # skip root only branches
abbr pstreeu 'pstree -u $(whoami)' # my processes
abbr pstreew 'pstree -w' # wide output (otherwise truncated)
# TODO pstree on macos/linux differs - reconcile abbrs based on env? use macos rooted abbrs (i.e. pstrees => pstree -s) but then have it map to smth similar on linux?
function pstree
    # TODO use -g 2 by default on macOS (looks better IMO)
    command pstree -g 2 $argv
end
# TODO look into utils like fuser (not necessarily for abbrs, though maybe) but b/c I need to shore up my knowlege here, so much easier to diagnose what an app is doing if I can look at its external interactions (ie files, ports, etc)

if $IS_MACOS
    abbr --set-cursor='!' sedi "gsed -i 's/!//g'"
    abbr --set-cursor='!' sedd "gsed --debug -i 's/!//g'"
    # abbr sed gsed # encourage the use of gsed so it behaves like linux?
    #  i.e. gnu allows `sed -i` whereas BSD requires the extension `sed -i''` be passed
else
    abbr --set-cursor='!' sedi "sed -i 's/!//g'"
    abbr --set-cursor='!' sedd "sed --debug -i 's/!//g'"
end

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

function z
    # TLDR = wcl + z
    # FYI still uses z fish completions (b/c same name)

    # -- ensures $argv can have options to z (i.e. --clean)
    if string match --quiet --regex "github.com" -- $argv
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
bind ctrl-o custom-kill-command-word # ctrl +o ([o]verwrite command)
# bind '*' custom-kill-command-word # * alone works w/o interrupt mid suggestion
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
bind ctrl-q toggle-grc # terrible key choice (ctrl+q) but it isn't used currently so yeah


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

    # TODO what was the old "as-tree" command I used to use? was that a real thing or prototype idea on my part?

    # ask o1-mini to "write me a fish shell function that runs dpkg -L foo on a package and then takes the output and formats it in a tree hierarchy like the tree command"
    # this works, have not yet reviewed it... wanna save that for later video.. as I also found `cargo install treeify`
    function dpkg_tree_awk
        if not set -q argv[1]
            echo "Usage: dpkg_tree_awk <package_name>"
            return 1
        end

        set pkg $argv[1]

        dpkg -L $pkg | sort | awk '
      BEGIN {
          FS="/"
      }
      {
          # Remove empty first field if path starts with /
          start = 1
          if ($1 == "") {
              start = 2
          }
          # Print indentation
          for (i = start; i < NF; i++) {
              printf "    "
          }
          # Print the current directory or file
          print "└── " $NF
      }'
    end
    # TODO ask it to fix how disjoint things look at times, also to remove that first needless later of nesting, edge case
    # └── .
    #     └── lib.usr-is-merged
    # └── etc
    #     └── apparmor.d
    #         └── usr.sbin.cups-browsed
    #     └── cups
    #         └── cups-browsed.conf
    # └── lib
    #     └── systemd
    #         └── system
    #             └── cups-browsed.service
    # └── usr
    #     └── lib
    #         └── cups

end


if command -q watch
    # VERIFIED watch does this on both macos and ubuntu

    # FYI this is faster than using alias and more obvious what happens:
    function watch
        # FYI uses same pattern of passing $argv as is found in fish's alias helper
        TERM=xterm command watch $argv
        # if watch believes there are 16+ colors (8 regular + 8 brights) it will then init the brights to hard coded colors and screw up background colors too (i.e. for white)... so if it believes there are only 8 colors then it doesn't alter any of them IIUC: https://gitlab.com/procps-ng/procps/-/blob/master/src/watch.c#L181

        # good way to test my colors:
        # watch -n 0.5 --color -- "grc --colour=on kubectl describe pod/web"
    end

    # TODO do I like w mapping to watch? So far `w` isn't used otherwise
    export WATCH_INTERVAL=0.5 # I almost always set to 0.5
    abbr wa watch # prn add back "-n0.5" if issues w/ WATCH_INTERVAL
    abbr wag 'watch --no-title --color -- grc --colour=on'
    # to support --no-title, add --show-kind to kubectl get output
    # - saves top title line and blank line after it for screen realestate!
    # - also nukes showing time in upper right corner
    # - FYI --show-kind already enabled if multi types requested, so NBD
    abbr wak 'watch --no-title --color -- grc --colour=on kubectl get --show-kind' # using alot! I love this
    abbr wad 'watch --no-title --color -- grc --colour=on kubectl describe --show-kind' # using alot! I love this
    abbr wakp 'watch --no-title --color -- grc --colour=on kubectl get --show-kind pods'
    abbr wah 'watch --no-title --color -- http --pretty=colors'
    abbr wahv 'watch --no-title --color -- http --pretty=colors --verbose' # == --print HhBb (headers and body for both request and response)
    abbr wal 'watch --no-title --color -- grc --colour=on ls'
    abbr wat 'watch --no-title --color -- grc --colour=on tree'
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
    wc $argv | awk '{printf("lines: %'\''d\nwords: %'\''d\nchars: %'\''d\n", $1, $2, $3)}'
    # FYI comma delimitted support in awk is not POSIX compliant, but is supported in gawk and mawk IIUC
end

if command -q yq

    # helper to select a document by index from multidocument yaml file
    abbr pyqi "| yq eval 'select(documentIndex == 1) | .status'"
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

    abbr --add actw --set-cursor='!' --function actw_expanded # ! so we can tab complete workflow file/path

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

if command -q ollama
    abbr olc "ollama create"
    abbr olcp "ollama cp"
    abbr olh "ollama help"
    abbr oll "ollama list"
    abbr olp "ollama pull"
    abbr olps "ollama ps"
    abbr olpush "ollama push"
    abbr olr "ollama run --verbose"
    abbr olrm "ollama rm"

    # PRN - use grc with ollama serve too and write my own coloring config (have claude do it)... do this if I dislike using bat for this
    set -l ollama_serve "ollama serve 2>&1 | bat -pp -l log" # -pp to disable pager and use plain style (no line numbers).. w/o disable pager, on mac my pager setup prohibits streaming somehow (anyways just use this always)
    # OLLAMA_NUM_PARALLEL is to ensure maximum context size for a single request n_ctx (not split up by --parallel, which defaults to 4 on smaller qwen models)
    abbr ols "OLLAMA_NUM_PARALLEL=1 $ollama_serve"
    abbr olsd "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=1 $ollama_serve"
    abbr olsh "OLLAMA_NUM_PARALLEL=1 OLLAMA_KEEP_ALIVE=30m OLLAMA_HOST='http://0.0.0.0:11434' $ollama_serve"
    abbr olshd "OLLAMA_NUM_PARALLEL=1 OLLAMA_KEEP_ALIVE=30m OLLAMA_DEBUG=1 OLLAMA_HOST='http://0.0.0.0:11434' $ollama_serve"
    abbr ole "export OLLAMA_HOST='ollama:11434'"

    abbr olshow "ollama show"
end

# TODO point cd => cd2?
function cd2
    # --description "cd improved"

    # if file passed, cd to dirname
    #   cd2 /Users/wes/repos/github/g0t4/dotfiles/fish/load_last/misc-specific.fish
    #     => cd /Users/wes/repos/github/g0t4/dotfiles/fish/load_last
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

# *** PATH(s)

function _path_list
    for dir in $PATH
        if test -e $dir
            for item in $dir/*
                echo $dir$item
            end
            # PRN any filtering or additional info to show? i.e. file type? dir? etc...?
        end
    end
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
    echo $argv[1] | sed 's/.*\.//'
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

abbr --add _aio --function abbr_aio
function abbr_aio
    echo -n "video_editing_aio "
    abbr_videos_glob_for_current_dir
end

abbr shift_only 'for i in *.mkv; video_editing_just_shift_to_mp4_one_video $i; end'
function video_editing_just_shift_to_mp4_one_video
    # converts to mp4 + shifts by 100ms
    set video_file (realpath $argv[1])
    set output_file (string replace -r "\.mkv\$" ".shifted100ms.mp4" "$video_file")
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

        ffmpeg -i "$combined_file" -itsoffset 0.1 -i "$combined_file" -map 0:v -map 1:a -c:v copy -c:a aac "$output_file"
        trash $combined_file # be safe with rm, if it was wrong file I wanna have it be recoverable
    end


    # PRN skip if already exists?
    video_editing_gen_fcpxml $output_file
end

function video_editing_gen_fcpxml
    set video_file (realpath $argv[1])

    set python3 "$HOME/repos/github/g0t4/private-auto-edit-suggests/.venv/bin/python3"
    set script "$HOME/repos/github/g0t4/private-auto-edit-suggests/research/FCPX/05-auto-transcribe-after-split-FCPX-drop-offset-too.py"
    $python3 $script $video_file
end

abbr --add 7db --regex '\d+db' --function abbr_db
function abbr_db
    set boost $argv[1] # i.e. 7db (do not need to have dB captial B... db is fine)

    # if only one video in current dir, select it
    # exclude previous boosted vides i.e. .7dB.m4v
    set video_files (ls *.{mp4,m4v} | grep -vE "dB\.[a-z0-9]{3}\$")
    if test (count $video_files) -eq 1
        set video_file $video_files[1]
    end
    echo "video_editing_boost_audio_dB_by $boost $video_file"
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
abbr man1 "man -S 1"
abbr man2 "man -S 2"
# abbr mans "man -S 2" # maybe? or just learn 2 is syscalls
abbr man3 "man -S 3"
abbr man4 "man -S 4"
abbr man5 "man -S 5"
abbr man6 "man -S 6"
abbr man7 "man -S 7"
abbr mana "man -a" # open all matching pages
abbr mank apropos # man -k ~= apropos
abbr manf whatis # man -f == whatis
abbr manw "man -aw" # man -w == whereis for man pages, or map to whereis?
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
abbr mitmpgrep 'pgrep -ilf mitmproxy | grep -v "\--no-server" || true' # don't error if not found, avoid confusion
abbr mitmkill 'pgrep -ilf mitmproxy | grep -v "\--no-server" | awk "{print $1}" | xargs sudo kill -9 || true'
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


if command -q nvim
    abbr vim nvim
    abbr vimc command vim # fallback to vim if nvim issues
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

    abbr --set-cursor='!' -- vshn 'virsh net-!' # complete the net subcommand, might be cool to hit TAB too automatically... could an abbreviation generate any sort of keyboard input?
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

if command -q security
    # consider securityfp (add p to end) for passwords
    #   do this when I start using security command for other credential types
    abbr --set-cursor='!' securityf "security find-generic-password -w -s ! -a "
    abbr --set-cursor='!' securityrm "security delete-generic-password -s ! -a "
    abbr --set-cursor='!' securitya "security add-generic-password -s ! -a -w "
    function securitys # s as in set (or update)... doesn't matte
        # USE FOR BOTH ADD NEW, and UPDATE
        # assume called like:
        #   security -s svcname -a accountname
        # TODO is there a way to update w/o deleting and adding? IF NOT, add a function to take the args and call both commands
        if security find-generic-password $argv 2>/dev/null 1>/dev/null
            echo Found password, removing first
            if not security delete-generic-password $argv
                echo "Delete failed, aborting..."
                return -1
            end
        end
        # BTW -w must come last (not before -s/-a)... so dumb
        if not security add-generic-password $argv -w
            echo "add failed..."
            return -1
        end
    end
    complete -c securitys --short-option s --long-option service
    complete -c securitys --short-option a --long-option account
    # PRN other args for find/add/delete-generic-password

    # had ChatGPT do this based on man page of security cmd (since fish shell generated completions dont work for security subcommadns, just its options)
    #   man -P "col -b" security
    # Completions for the `security` command
    # TODO resume later, just a reminder to add these
    # FYI right now can tab complete subcommand names which is likely enough
    # Function to provide security subcommands
    function __fish_security_subcommands
        echo help list-keychains default-keychain login-keychain \
            create-keychain delete-keychain lock-keychain unlock-keychain \
            set-keychain-settings set-keychain-password show-keychain-info \
            dump-keychain create-keypair add-generic-password \
            add-internet-password add-certificates find-generic-password \
            delete-generic-password set-generic-password-partition-list \
            find-internet-password delete-internet-password \
            set-internet-password-partition-list find-key set-key-partition-list \
            find-certificate find-identity delete-certificate \
            delete-identity set-identity-preference get-identity-preference \
            create-db export import cms install-mds \
            add-trusted-cert remove-trusted-cert dump-trust-settings \
            user-trust-settings-enable trust-settings-export \
            trust-settings-import verify-cert authorize \
            authorizationdb execute-with-privileges leaks smartcards \
            list-smartcards export-smartcard error \
            | tr ' ' '\n'
    end

    # Add completions for each subcommand
    complete -c security -a "(__fish_security_subcommands)"

    # TODO chatgpt sugggested the following... but IIUC I just need to call complete multiple times and provide a desc for each subarg OR
    #  TODO lookup how __fish_seen_* helpers work.. if they can provide descriptions or not?
    ## Add descriptions for each specific subcommand
    #complete -c security -n '__fish_seen_subcommand_from help' -d "Show all commands, or usage for a command"
    #complete -c security -n '__fish_seen_subcommand_from list-keychains' -d "Display or manipulate the keychain search list"
    #complete -c security -n '__fish_seen_subcommand_from default-keychain' -d "Display or set the default keychain"
    #complete -c security -n '__fish_seen_subcommand_from login-keychain' -d "Display or set the login keychain"
    #complete -c security -n '__fish_seen_subcommand_from create-keychain' -d "Create keychains"
    #complete -c security -n '__fish_seen_subcommand_from delete-keychain' -d "Delete keychains and remove them from the search list"
    #complete -c security -n '__fish_seen_subcommand_from lock-keychain' -d "Lock the specified keychain"
    #complete -c security -n '__fish_seen_subcommand_from unlock-keychain' -d "Unlock the specified keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-keychain-settings' -d "Set settings for a keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-keychain-password' -d "Set password for a keychain"
    #complete -c security -n '__fish_seen_subcommand_from show-keychain-info' -d "Show the settings for keychain"
    #complete -c security -n '__fish_seen_subcommand_from dump-keychain' -d "Dump the contents of one or more keychains"
    #complete -c security -n '__fish_seen_subcommand_from create-keypair' -d "Create an asymmetric key pair"
    #complete -c security -n '__fish_seen_subcommand_from add-generic-password' -d "Add a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from add-internet-password' -d "Add an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from add-certificates' -d "Add certificates to a keychain"
    #complete -c security -n '__fish_seen_subcommand_from find-generic-password' -d "Find a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from delete-generic-password' -d "Delete a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from set-generic-password-partition-list' -d "Set the partition list of a generic password item"
    #complete -c security -n '__fish_seen_subcommand_from find-internet-password' -d "Find an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from delete-internet-password' -d "Delete an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from set-internet-password-partition-list' -d "Set the partition list of an internet password item"
    #complete -c security -n '__fish_seen_subcommand_from find-key' -d "Find keys in the keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-key-partition-list' -d "Set the partition list of a key"
    #complete -c security -n '__fish_seen_subcommand_from find-certificate' -d "Find a certificate item"
    #complete -c security -n '__fish_seen_subcommand_from find-identity' -d "Find an identity (certificate + private key)"
    #complete -c security -n '__fish_seen_subcommand_from delete-certificate' -d "Delete a certificate from a keychain"
    #complete -c security -n '__fish_seen_subcommand_from delete-identity' -d "Delete a certificate and its private key from a keychain"
    #complete -c security -n '__fish_seen_subcommand_from set-identity-preference' -d "Set the preferred identity to use for a service"
    #complete -c security -n '__fish_seen_subcommand_from get-identity-preference' -d "Get the preferred identity to use for a service"
    #complete -c security -n '__fish_seen_subcommand_from create-db' -d "Create a db using the DL"
    #complete -c security -n '__fish_seen_subcommand_from export' -d "Export items from a keychain"
    #complete -c security -n '__fish_seen_subcommand_from import' -d "Import items into a keychain"
    #complete -c security -n '__fish_seen_subcommand_from cms' -d "Encode or decode CMS messages"
    #complete -c security -n '__fish_seen_subcommand_from install-mds' -d "Install (or re-install) the MDS database"
    #complete -c security -n '__fish_seen_subcommand_from add-trusted-cert' -d "Add trusted certificate(s)"
    #complete -c security -n '__fish_seen_subcommand_from remove-trusted-cert' -d "Remove trusted certificate(s)"
    #complete -c security -n '__fish_seen_subcommand_from dump-trust-settings' -d "Display contents of trust settings"
    #complete -c security -n '__fish_seen_subcommand_from user-trust-settings-enable' -d "Display or manipulate user-level trust settings"
    #complete -c security -n '__fish_seen_subcommand_from trust-settings-export' -d "Export trust settings"
    #complete -c security -n '__fish_seen_subcommand_from trust-settings-import' -d "Import trust settings"
    #complete -c security -n '__fish_seen_subcommand_from verify-cert' -d "Verify certificate(s)"
    #complete -c security -n '__fish_seen_subcommand_from authorize' -d "Perform authorization operations"
    #complete -c security -n '__fish_seen_subcommand_from authorizationdb' -d "Make changes to the authorization policy database"
    #complete -c security -n '__fish_seen_subcommand_from execute-with-privileges' -d "Execute tool with privileges"
    #complete -c security -n '__fish_seen_subcommand_from leaks' -d "Run /usr/bin/leaks on this process"
    #complete -c security -n '__fish_seen_subcommand_from smartcards' -d "Enable, disable or list disabled smartcard tokens"
    #complete -c security -n '__fish_seen_subcommand_from list-smartcards' -d "Display available smartcards"
    #complete -c security -n '__fish_seen_subcommand_from export-smartcard' -d "Export/display items from a smartcard"
    #complete -c security -n '__fish_seen_subcommand_from error' -d "Display a descriptive message for the given error code(s)"

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
    abbr --set-cursor='!' pmss "sudo pacman -Ss '^!'" # (s)earch, name starts with
    abbr --set-cursor='!' pm_search "sudo pacman -Ss '^!'" # reminder only
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
    abbr --set-cursor='!' pmqg "pacman -Q | grep -i '!'" # I prefer grep, it's just easier to not need another tool specific option
    abbr --set-cursor='!' pmqgs "pacman -Q | grep -i '^!'"
    #
    abbr pmql "pacman -Ql" # (l)ist files for pkg, can list multiple too (in which case first col is pkg name)
    # TODO any reason why I wouldn't just use -Fl always? perhaps if I custom build a pkg?
    abbr --set-cursor='!' pmqlt "pacman -Qlq ! | treeify " # tree like list (-q == --quiet => show less info, in this case dont list pkg name column, just file paths)
    abbr --set-cursor='!' pm_listinstalledpkgfiles "pacman -Qlq ! | treeify" # reminder
    #pacman -Qk fish # verify installed files
    abbr pmqo "pacman -Qo" # (o)wned by pkg
    abbr pm_whoownsfile "pacman -Qo"
    #pacman -Qo /path/to/file # find package for an installed file
    #pacman -Qo ip # owned by iproute2
    #
    # *** explicit / implicit installed pkgs
    abbr pmqe "pacman -Qe" # list (e)xplicitly installed pkgs
    #pacman -Qet # explicit installed packages (not required as deps of another package)
    #pacman -Qdt # orphans (not explicitly installed, also no longer a dep of another package)

    # *** Files database
    abbr pmf "pacman -F" # (f)ile => find file in remote packages
    # pacman -F /path/to/file # find file in remote package (i.e. not yet installed)
    # pacman -F ollama # or, w/o path => find what provides ollama command
    #
    # FYI for -Fl vs -Ql... mostly gonna be ok to use -Fl... but, if build a pkg by hand it might only be avail in locally installed packages
    abbr pmfl "pacman -Fl" # (l)ist files for (remote) pkg
    abbr --set-cursor='!' pmflt "pacman -Flq ! | treeify" # treeify list of files
    abbr --set-cursor='!' pm_listremotepkgfiles "pacman -Flq ! | treeify" # reminder
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
    abbr --set-cursor='!' nv "nvidia-!" # kinda weird with space => dash but lets see how I feel as i use it and if it collides w/ anything else

    # TODO can I find a better source of copmletions?
    complete -c nvidia-container-cli --no-files -a "list info configure --help"

    # abbr nvsmi "nvidia-smi"
    # abbr nvsmiq "nvidia-smi --query"
    # abbr nvsmil "nvidia-smi --list-gpus"
    # abbr nvcclii "nvidia-container-cli info"
    # abbr nvcclil "nvidia-container-cli list"
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

    if $IS_MACOS then
        # -F => use finder to ensure `Put Back` works
        #   otherwise item is in trash but have to manually restore location
        for file in $argv
            if test -e $file
                command trash -F $file
            end
        end
    else
        echo "TODO not implemented yet for your OS"
    end
end

if $IS_MACOS then
    abbr find gfind
    abbr finde gfind . -executable
    # gfind == GNU find, has -exeuctable arg (among other differences)
    # make sure to run fish_update_completions after installing for completions
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
    abbr --set-cursor='!' lsmodg "sudo lsmod | grep -i '!'"

    # lsmem
    abbr lsmem "lsmem --output-all"

    # lspath
    # lstopo

    # lsof
    # *** process info
    # files for a process:
    # TODO how to deal with multiple matches, I don't like using head but at least it is obvious in the expanded command so leave it for now
    abbr --set-cursor="!" lsofp 'lsof -p $(pgrep -if "!" | head -1)'

    # lsusb
    abbr lsusb "lsusb -tv" # concise tree, a few more details
    abbr lsusbv "lsusb -v" # very detailed

    # dmesg
    abbr --set-cursor='!' dmesgg "sudo dmesg | grep -i '!'"


end


# *** asciinema
abbr anr 'asciinema rec --overwrite test.cast' # PRN remake in fish:    abbr --set-cursor '!' --add anr 'asciinema rec --overwrite !.cast'
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
abbr vllmb "vllm bench"
abbr vllmc "vllm chat"
abbr vllmg "vllm complete"
