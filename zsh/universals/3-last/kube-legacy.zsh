#
#! LEGACY ALIASES for ZSH ONLY (newer set uses abbr in fish - can always port back to zsh later, right now I am super happy with fish and would like to reduce some overhead in ealias / zsh maint + take advantage of abbr features like cursor position in fish 3.6.0+)

export KUBECTL_EXTERNAL_DIFF="icdiff -r" # use icdiff for kubectl diff (slick!)... FYI $1 and $2 are directories to compare (hence the -r)

ealias kver='grc kubectl version'
# explain
ealias ke='grc kubectl explain'
ealias kep='grc kubectl explain pods' # example
ealias keps='grc kubectl explain pods.spec' # example
ealias ker='grc kubectl explain --recursive'
#
ealias kav='grc kubectl api-versions'
ealias kar='grc kubectl api-resources'
ealias karn='grc kubectl api-resources --namespaced=true'
ealias karg='grc kubectl api-resources --namespaced=false' # (g)lobal

# grc kubectl options

# kubectl alpha

# *** get
ealias kg="grc kubectl get"
ealias kgf="grc kubectl get -f" # status of resources defined in yml file
#
ealias kgns="grc kubectl get namespaces"
# TODO redo get aliases to use abbreviations where applicable (ie n=>ns)
#
ealias kga="grc kubectl get all"
ealias kgaa="grc kubectl get all -A" # -A/--all-namespaces
#
ealias kgp="grc kubectl get pods"
ealias kgpa="grc kubectl get pods -A"
ealias kgpaw="grc kubectl get pods -A --watch"
#
# PRN prune list or add other resource types:
ealias kgs="grc kubectl get svc"
ealias kgno="grc kubectl get nodes"
ealias kgsa="grc kubectl get serviceaccounts"
ealias kgcr="grc kubectl get clusterroles"
ealias kgcrb="grc kubectl get clusterrolebindings"
ealias kgro="grc kubectl get roles"
ealias kgrob="grc kubectl get rolebindings"
ealias kgcm="grc kubectl get configmaps"
ealias kgsec="grc kubectl get secrets"
ealias kgcrd="grc kubectl get customresourcedefinitions"

# create
ealias kc='kubectl create'
ealias kcf='kubectl create -f' # from file
# apply
ealias kaf='kubectl apply -f' # create or modify
# delete
ealias kdel='kubectl delete'
ealias kdelf='kubectl delete -f'
# replace
ealias krf='kubectl replace -f' # delete and then create
# diff
ealias kd='kubectl diff' # diff current (status) vs desired state (spec)
ealias kdf='kubectl diff -f'
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

ealias kdesc='grc kubectl describe' # ~ docker inspect
ealias kdescf='grc kubectl describe -f'
ealias krun='kubectl run' # ~ docker container run
ealias kexec='kubectl exec -it' # ~ docker container exec
ealias kattach='kubectl attach -it' # ~ docker container attach
ealias kcp='kubectl cp' # ~ docker container cp
ealias kpf='kubectl port-forward' # setup proxy to access pod's port from host machine # ~ docker container run -p flag
# kubectl expose
# kubectl wait

# logs
ealias kl='kubectl logs'
ealias klf='kubectl logs --follow'

# conte(x)t => muscle memory with docker `dxls`=`docker context ls`, so => kxls
ealias kx='kubectl config'
ealias kxu='kubectl config use-context'
ealias kxls='kubectl config get-contexts'
ealias kxv='kubectl config view'

# kubectl cluster-info dump
ealias ktop='kubectl top pod --all-namespaces'
ealias ktopn='kubectl top node'

# kubectl proxy
# kubectl debug
# kubectl events

# kubectl plugin list

# *** minikube
ealias mk="minikube"
ealias mkst="minikube status"
ealias mkstop="minikube stop"
ealias mkstart="minikube start"
ealias mkpause="minikube pause"
ealias mkunpause="minikube unpause"

ealias mkno="minikube node list"

ealias mkd="minikube dashboard --port 9090"
ealias mksls="minikube service list"
# minikube tunnel
ealias mkals="minikube addons list"
ealias mkae="minikube addons enable"
ealias mkad="minikube addons disable"

ealias mked='eval $(minikube docker-env)' # access docker container runtime (if using)
# ealias mkep='eval $(minikube podman-env)' # access podman container runtime (if using)

ealias mkp="minikube profile list"

ealias mkk="minikube kubectl"
