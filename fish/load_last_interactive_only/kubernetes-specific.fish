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
    export "KUBECTL_EXTERNAL_DIFF=icdiff -r" # use icdiff for kubectl diff (slick!)... FYI $1 and $2 are directories to compare (hence the -r)

    abbr --command kubectl -- oy '-o yaml' # I used to pipe to yq... but I wrapped 'grc kubectl' to be 'kubectl' and don't need yq now
    abbr --command kubectl -- ow '-o wide' # I don't believe this will cause collisions b/c it is not a word I expect to use in other contexts, lets see

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

    # abbr h helm # FYI I gave `h` to history command

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
