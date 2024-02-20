
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

    eabbr sc 'sudo systemctl'
    eabbr scu 'sudo systemctl --user'

    eabbr scm 'man systemd.index' # great entrypoint to systemd man pages

    eabbr scs 'sudo systemctl status'
    eabbr scstop 'sudo systemctl stop'
    eabbr scstart 'sudo systemctl start'
    eabbr screstart 'sudo systemctl restart'
    eabbr scenable 'sudo systemctl enable'
    eabbr scdisable 'sudo systemctl disable'
    eabbr sck 'sudo systemctl kill' # PRN --signal=SIGKILL?

    eabbr sccat 'sudo systemctl cat'
    eabbr scedit 'sudo systemctl edit'
    eabbr screvert 'sudo systemctl revert'
    eabbr scshow 'sudo systemctl show'

    eabbr scls 'sudo systemctl list-units'
    eabbr sclsf 'sudo systemctl list-unit-files'
    eabbr sclss 'sudo systemctl list-sockets'
    eabbr sclsd 'sudo systemctl list-dependencies'

    eabbr jc 'sudo journalctl -u'
    eabbr jcu 'sudo journalctl --user-unit'

    eabbr jcb 'sudo journalctl --boot -u' # current boot
    eabbr jcb1 'sudo journalctl --boot=-1 -u' # previous boot
    eabbr jcboots 'sudo journalctl --list-boots'

    eabbr jcs 'sudo journalctl --since "1min ago" -u'
    eabbr jck 'sudo journalctl -k' # kernel/dmesg

    eabbr jcf 'sudo journalctl --follow -u'
    eabbr jcfa 'sudo journalctl --follow --no-tail -u' # all lines + follow

    # WIP - figure out what I want for cleanup, when testing I often wanna just clear all logs and try some activity to simplify looking at journalctl history, hence jcnuke
    eabbr jcnuke 'sudo journalctl --rotate --vacuum-time=1s' # ~effectively rotate (archive all active journal files) then nuke (all archived journal files)
    eabbr jcr 'sudo journalctl --rotate' # rotate (archive) all active journal files (new journal files going forward)
    eabbr jcvs 'sudo journalctl --vacuum-size=100M' # vacuum logs to keep total size under 100M
    eabbr jcdu 'sudo journalctl --disk-usage' # total disk usage
end

# *** containerd
if command -q ctr

    eabbr ctr 'sudo ctr'
    eabbr ctrn 'sudo ctr namespaces ls'

    # containers:
    eabbr ctrc 'sudo ctr container ls'
    eabbr ctrci 'sudo ctr container info'
    eabbr ctrcrm 'sudo ctr container rm'

    # images:
    eabbr ctri 'sudo ctr image ls'
    abbr ctripull --set-cursor='!' 'sudo ctr image pull docker.io/library/!'
    abbr ctrirm --set-cursor='!' 'sudo ctr image rm docker.io/library/!'

    # tasks:
    eabbr ctrtls 'sudo ctr task ls'
    eabbr ctrtps 'sudo ctr task ps' # by CID
    eabbr ctrta 'sudo ctr task attach'
    eabbr ctrtrm 'sudo ctr task rm'
    eabbr ctrtk 'sudo ctr task kill --all'
    eabbr ctrtks 'sudo ctr task kill --all --signal=SIGKILL'
    eabbr ctrtpause 'sudo ctr task pause'
    eabbr ctrtresume 'sudo ctr task resume'
    eabbr ctrtstart 'sudo ctr task start' # created container that is not running
    eabbr ctrtexec 'sudo ctr task exec --tty --exec-id 100 '

    # run:
    eabbr ctrr 'sudo ctr run -t --rm'
    # demo examples:
    eabbr ctrrnd 'sudo ctr run -d docker.io/library/nginx:latest web' # w/o host networking
    eabbr ctrrn 'sudo ctr run -t --rm --net-host docker.io/library/nginx:latest web' # w/ host networking

    # content
    # leases
    # snapshots

end

if command -q k3s

    eabbr k3s 'sudo k3s' # most helpful with say `sudo k3s ctr ...` b/c k3s containerd sock is owned by root:root
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

    eabbr kver 'grc kubectl version'
    # explain
    eabbr ke 'grc kubectl explain'
    eabbr kep 'grc kubectl explain pods' # example
    eabbr keps 'grc kubectl explain pods.spec' # example
    eabbr ker 'grc kubectl explain --recursive'
    #
    eabbr kav 'grc kubectl api-versions'
    eabbr kar 'grc kubectl api-resources'
    eabbr karn 'grc kubectl api-resources --namespaced=true'
    eabbr karg 'grc kubectl api-resources --namespaced=false' # (g)lobal

    # grc kubectl options

    # kubectl alpha

    # *** get
    eabbr kg 'grc kubectl get'
    eabbr kgf 'grc kubectl get -f' # status of resources defined in yml file
    #
    eabbr kgns 'grc kubectl get namespaces'
    # TODO redo get aliases to use abbreviations where applicable (ie n=>ns)
    #
    eabbr kga 'grc kubectl get all'
    eabbr kgaa 'grc kubectl get all -A' # -A/--all-namespaces
    #
    eabbr kgp 'grc kubectl get pods' # alias: po (gonna go with p only for now)
    eabbr kgpa 'grc kubectl get pods -A'
    eabbr kgpaw 'grc kubectl get pods -A --watch'
    #
    # PRN prune list or add other resource types:
    eabbr kgcj 'grc kubectl get cronjobs'
    eabbr kgcm 'grc kubectl get configmaps' # alias: cm
    eabbr kgcr 'grc kubectl get clusterroles'
    eabbr kgcrb 'grc kubectl get clusterrolebindings'
    eabbr kgcrd 'grc kubectl get customresourcedefinitions' # alias: crd,crds
    eabbr kgds 'grc kubectl get daemonsets' # alias: ds
    eabbr kgep 'grc kubectl get endpoints' # alias: ep
    eabbr kgev 'grc kubectl get events' # alias: ev
    eabbr kging 'grc kubectl get ingresses' # alias: ing
    eabbr kgj 'grc kubectl get jobs'
    eabbr kgno 'grc kubectl get nodes' # alias: no
    eabbr kgpv 'grc kubectl get persistentvolumes' # alias: pv
    eabbr kgpvc 'grc kubectl get persistentvolumeclaims' # alias: pvc
    eabbr kgrb 'grc kubectl get rolebindings'
    eabbr kgro 'grc kubectl get roles'
    eabbr kgrs 'grc kubectl get replicasets' # alias: rs
    eabbr kgs 'grc kubectl get svc'
    eabbr kgsa 'grc kubectl get serviceaccounts' # alias: sa
    eabbr kgsc 'grc kubectl get storageclasses' # alias: sc
    eabbr kgsec 'grc kubectl get secrets'
    eabbr kgsts 'grc kubectl get statefulsets' # alias: sts
    eabbr kgsvc 'grc kubectl get services' # alias: svc

    # create
    eabbr kc 'kubectl create'
    eabbr kcf 'kubectl create -f' # from file
    # apply
    eabbr kaf 'kubectl apply -f' # create or modify
    # delete
    eabbr kdel 'kubectl delete'
    eabbr kdelf 'kubectl delete -f'
    # replace
    eabbr krf 'kubectl replace -f' # delete and then create
    # diff
    eabbr kd 'kubectl diff' # diff current (status) vs desired state (spec)
    eabbr kdf 'kubectl diff -f'
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

    eabbr kdesc 'grc kubectl describe' # ~ docker inspect
    eabbr kdescf 'grc kubectl describe -f'
    eabbr krun 'kubectl run' # ~ docker container run
    eabbr kexec 'kubectl exec -it' # ~ docker container exec
    eabbr kattach 'kubectl attach -it' # ~ docker container attach
    eabbr kcp 'kubectl cp' # ~ docker container cp
    eabbr kpf 'kubectl port-forward' # setup proxy to access pod's port from host machine # ~ docker container run -p flag
    # kubectl expose
    # kubectl wait

    # logs
    eabbr kl 'kubectl logs'
    eabbr klf 'kubectl logs --follow'

    # conte(x)t => muscle memory with docker `dxls`=`docker context ls`, so => kxls
    eabbr kx 'kubectl config'
    eabbr kxu 'kubectl config use-context'
    eabbr kxls 'kubectl config get-contexts'
    eabbr kxv 'kubectl config view'

    # kubectl cluster-info dump
    eabbr ktp 'kubectl top pod --all-namespaces'
    eabbr ktn 'kubectl top node'

    # kubectl proxy
    # kubectl debug
    # kubectl events

    # kubectl plugin list

end

if command -q minikube

    eabbr mk minikube
    eabbr mkst 'minikube status'
    eabbr mkstop 'minikube stop'
    eabbr mkstart 'minikube start'
    eabbr mkpause 'minikube pause'
    eabbr mkunpause 'minikube unpause'

    eabbr mkno 'minikube node list'

    eabbr mkd 'minikube dashboard --port 9090'
    eabbr mksls 'minikube service list'
    # minikube tunnel
    eabbr mkals 'minikube addons list'
    eabbr mkae 'minikube addons enable'
    eabbr mkad 'minikube addons disable'

    eabbr mked 'eval $(minikube docker-env)' # access docker container runtime (if using)
    # eabbr mkep 'eval $(minikube podman-env)' # access podman container runtime (if using)

    eabbr mkp 'minikube profile list'

    eabbr mkk 'minikube kubectl'

end
