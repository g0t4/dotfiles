
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
bind -k sdc kill-word # shift+del to kill forward a word (otherwise its esc+d only), I have a habit of using this (not sure why, probably an old keymapping in zsh or?)


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

if command -q kubectl
    export KUBECTL_EXTERNAL_DIFF="icdiff -r" # use icdiff for kubectl diff (slick!)... FYI $1 and $2 are directories to compare (hence the -r)

    abbr kver 'grc kubectl version'
    # explain
    abbr ke 'grc kubectl explain'
    abbr kep 'grc kubectl explain pods' # example
    abbr keps 'grc kubectl explain pods.spec' # example
    abbr ker 'grc kubectl explain --recursive'
    #
    abbr kav 'grc kubectl api-versions'
    abbr kar 'grc kubectl api-resources'
    abbr karn 'grc kubectl api-resources --namespaced=true'
    abbr karg 'grc kubectl api-resources --namespaced=false' # (g)lobal

    # TODO how do I feel about this:
    abbr --position=anywhere -- oy '-o yaml | bat -l yml'
    # grc kubectl options

    # kubectl alpha

    # *** get
    abbr kg 'grc kubectl get'
    abbr kgf 'grc kubectl get -f' # status of resources defined in yml file
    #
    abbr kgns 'grc kubectl get namespaces'
    # TODO redo get aliases to use abbreviations where applicable (ie n=>ns)
    #
    abbr kga 'grc kubectl get all'
    abbr kgaa 'grc kubectl get all -A' # -A/--all-namespaces
    abbr kgas 'grc kubectl get all --show-labels'
    #
    abbr kgp 'grc kubectl get pods' # alias: po (gonna go with p only for now)
    abbr kgpa 'grc kubectl get pods -A'
    abbr kgpaw 'grc kubectl get pods -A --watch'
    #
    # PRN prune list or add other resource types:
    abbr kgcj 'grc kubectl get cronjobs'
    abbr kgcm 'grc kubectl get configmaps' # alias: cm
    abbr kgcr 'grc kubectl get clusterroles'
    abbr kgcrb 'grc kubectl get clusterrolebindings'
    abbr kgcrd 'grc kubectl get customresourcedefinitions' # alias: crd,crds
    abbr kgds 'grc kubectl get daemonsets' # alias: ds
    abbr kgep 'grc kubectl get endpoints' # alias: ep
    abbr kgepA 'grc kubectl get endpoints -A' # all endpoints
    abbr kgev 'grc kubectl get events' # alias: ev
    abbr kging 'grc kubectl get ingresses' # alias: ing
    abbr kgj 'grc kubectl get jobs'
    abbr kgno 'grc kubectl get nodes' # alias: no
    abbr kgpv 'grc kubectl get persistentvolumes' # alias: pv
    abbr kgpvc 'grc kubectl get persistentvolumeclaims' # alias: pvc
    abbr kgrb 'grc kubectl get rolebindings'
    abbr kgro 'grc kubectl get roles'
    abbr kgrs 'grc kubectl get replicasets' # alias: rs
    abbr kgs 'grc kubectl get svc'
    abbr kgsa 'grc kubectl get serviceaccounts' # alias: sa
    abbr kgsc 'grc kubectl get storageclasses' # alias: sc
    abbr kgsec 'grc kubectl get secrets'
    abbr kgsts 'grc kubectl get statefulsets' # alias: sts
    abbr kgsvc 'grc kubectl get services' # alias: svc

    # create
    abbr kc 'kubectl create'
    abbr kcf 'kubectl create -f' # from file
    # apply
    abbr kaf 'kubectl apply -f' # create or modify
    # delete
    abbr kdel 'kubectl delete'
    abbr kdelf 'kubectl delete -f'
    # replace
    abbr krf 'kubectl replace -f' # delete and then create
    # diff
    abbr kd 'kubectl diff' # diff current (status) vs desired state (spec)
    abbr kdf 'kubectl diff -f'
    # kubectl edit
    # kubectl patch
    # kubectl set
    # kubectl kustomize
    #
    # kubectl label
    # kubectl annotate
    #
    # kubectl rollout
    # kubectl scale
    # kubectl autoscale

    abbr kdesc 'grc kubectl describe' # ~ docker inspect
    abbr kdescf 'grc kubectl describe -f'
    abbr krun 'kubectl run' # ~ docker container run
    abbr kexec 'kubectl exec -it' # ~ docker container exec
    abbr kattach 'kubectl attach -it' # ~ docker container attach
    abbr kcp 'kubectl cp' # ~ docker container cp
    abbr kpf 'kubectl port-forward' # setup proxy to access pod's port from host machine # ~ docker container run -p flag
    # kubectl expose
    # kubectl wait

    # logs
    abbr kl 'kubectl logs'
    abbr klf 'kubectl logs --follow'

    # conte(x)t => muscle memory with docker `dxls`=`docker context ls`, so => kxls
    abbr kx 'kubectl config'
    abbr --set-cursor='!' -- kxs 'kubectl config set-context --current --namespace=!' # kxsn if want more set abbr's
    abbr --set-cursor='!' -- kns 'kubectl config set-context --current --namespace=!' # this is easier to remember BUT does not fit into kx abbr "namespacing" (pun intended)
    abbr kxu 'kubectl config use-context'
    abbr kxls 'kubectl config get-contexts'
    abbr kxv 'kubectl config view'

    # kubectl cluster-info dump
    abbr ktp 'kubectl top pod --all-namespaces'
    abbr ktn 'kubectl top node'

    # kubectl proxy
    # kubectl debug
    # kubectl events

    # kubectl plugin list
    abbr kpls 'kubectl plugin list'
    # krew
    abbr krew 'kubectl krew'

end

if command -q minikube

    abbr mk minikube
    abbr mkst 'minikube status'
    abbr mkstop 'minikube stop'
    abbr mkstart 'minikube start'
    abbr mkpause 'minikube pause'
    abbr mkunpause 'minikube unpause'

    abbr mkno 'minikube node list'

    abbr mkd 'minikube dashboard --port 9090'
    abbr mksls 'minikube service list'
    # minikube tunnel
    abbr mkals 'minikube addons list'
    abbr mkae 'minikube addons enable'
    abbr mkad 'minikube addons disable'

    abbr mked 'eval $(minikube docker-env)' # access docker container runtime (if using)
    # abbr mkep 'eval $(minikube podman-env)' # access podman container runtime (if using)

    abbr mkp 'minikube profile list'

    abbr mkk 'minikube kubectl'

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
    # get         download extended information of a named release
    #    all         download all information for a named release
    #    hooks       download all hooks for a named release
    #    manifest    download the manifest for a named release
    #    metadata    This command fetches metadata for a given release
    #    notes       download the notes for a named release
    #    values      download the values file for a named release
    # help        Help about any command
    # history/hist     fetch release history
    abbr hh 'helm history'
    # install     install a chart
    abbr hin 'helm install'
    # lint        examine a chart for possible issues
    # list/ls        list releases
    abbr hls 'helm list' # PRN default list args?
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
    abbr --set-cursor='!' -- hic "helm show chart ! | bat -l yml"
    #    crds        show the chart's CRDs
    #    readme      show the chart's README
    abbr --set-cursor='!' -- hir "helm show readme ! | bat -l md"
    #    values      show the chart's values
    abbr --set-cursor='!' -- hiv "helm show values ! | bat -l yml"
    #
    # status      display the status of the named release
    abbr hst 'helm status'
    #
    # template    locally render templates
    abbr --set-cursor='!' -- ht 'helm template ! | bat -l yml' # repo/chart-name
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

# *** processes ***
abbr psg "ps aux | grep -i "
abbr pgrep "pgrep -il" # -l long output (show what matched => process name)
abbr pgrepf "pgrep -ilf" # -f match full command line, -l show what matched (full line)


# TODO port more dns/arp helpers here
function _flush_dns
    # PRN check if macos, if not use different command or warn
    sudo killall -HUP mDNSResponder
end
