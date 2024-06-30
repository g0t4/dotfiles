
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

    abbr --position=anywhere -- oy '-o yaml | yq' # format + filter with yq (plus I like yq format better than bat -l yml currently)
    abbr --position=anywhere -- ow '-o wide' # I don't believe this will cause collisions b/c it is not a word I expect to use in other contexts, lets see

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
    abbr mkt 'minikube tunnel' # make LoadBalancer services routeable from host
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

# *** processes ***
abbr psg "ps aux | grep -i "
abbr pgrep "pgrep -ilf" # -l long output (show what matched => process name), -f match full command line, -l show what matched (full line)


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
# ctrl+delete to delete next word (after cursor)
bind '[3;5~' kill-word # PRN kill-big-word?
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
bind \co custom-kill-command-word # ctrl +o ([o]verwrite command)
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
bind \cq toggle-grc # terrible key choice (ctrl+q) but it isn't used currently so yeah


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
    abbr w watch # prn add back "-n0.5" if issues w/ WATCH_INTERVAL
    abbr wg 'watch --no-title --color -- grc --colour=on'
    # to support --no-title, add --show-kind to kubectl get output
    # - saves top title line and blank line after it for screen realestate!
    # - also nukes showing time in upper right corner
    # - FYI --show-kind already enabled if multi types requested, so NBD
    abbr wk 'watch --no-title --color -- grc --colour=on kubectl get --show-kind' # using alot! I love this
    abbr wkp 'watch --no-title --color -- grc --colour=on kubectl get --show-kind pods'
    abbr wc 'watch --no-title --color -- grc --colour=on curl' #? shot in the dark, I probably won't ever use this :)... just capturing an idea => perhaps wh for "watch + http(ie)"?
    abbr wl 'watch --no-title --color -- grc --colour=on ls'
    abbr wt 'watch --no-title --color -- grc --colour=on tree'
    # for k8s prefer kubectl --watch b/c grc colors the output w/o issues.. but when it is not avail to continually monitor then use watch command w/ color output:
    #   watch -n0.5 --color -- grc --colour=on kubectl rollout status deployments 

    # FYI find terminfo for a TERM value:
    #    diff_two_commands 'infocmp xterm' 'infocmp xterm-256color'
    #
    # xterm = treated as 8 color
    # FYI xterm-16color still has brights issue
    # xterm-256color = treated as 256 colors (IIUC this is how background colors for bright white gets messed up)

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
    abbr olr "ollama run"
    abbr olrm "ollama rm"
    abbr ols "ollama serve"
    abbr olsd "OLLAMA_DEBUG=1 ollama serve"
    abbr olshow "ollama show"
end

# TODO point cd => cd2?
function cd2
    # --description "cd improved"

    # if file passed, cd to dirname
    #   cd2 /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/fish/load_last/misc-specific.fish
    #     => cd /Users/wes/repos/wes-config/wes-bootstrap/subs/dotfiles/fish/load_last
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

# FYI `veaud<TAB>` works in fish shell to complete this func:
function video_editing_1_check_audio
    # only arg would be file paths (i.e. from glob like *.mp4), btw dont need to pass any paths and it will do all *.mp4 in current dir
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_1_check_audio $paths"
end

# FYI `veconv<TAB>` works in fish shell to complete this func:
function video_editing_2_convert_30fps
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_2_convert_30fps $argv"
end

function video_editing_extract_most_scene_change_thumbnails
    set -l paths (quote_paths $argv)
    zsh -ic "video_editing_extract_most_scene_change_thumbnails $argv"
end
