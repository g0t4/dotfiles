export DOCKER_HIDE_LEGACY_COMMANDS=1 # less clutter in help output

#set use_grc_with_docker yes
set use_grc_with_docker no
function grcify
    if test $use_grc_with_docker = yes
        echo -n "grc $argv"
    else
        echo -n "$argv"
    end
end

abbr din 'docker inspect'

# stack
abbr dst 'docker stack'
abbr dstd 'docker stack deploy -c'
abbr dstls 'docker stack ls'
abbr dstps 'docker stack ps'
abbr dstrm 'docker stack rm'
abbr dsts 'docker stack services'
# service
abbr dse 'docker service'
abbr dsec 'docker service create'
abbr dsei 'docker service inspect'
abbr dsel 'docker service logs'
abbr dsels 'docker service ls'
abbr dseps 'docker service ps'
abbr dserm 'docker service rm'
abbr dserb 'docker service rollback'
abbr dses 'docker service scale'
abbr dseu 'docker service update'
abbr dseuf 'docker service update --force'
# swarm
abbr dsw 'docker swarm'
abbr dswi 'docker swarm init'
abbr dswj 'docker swarm join'
abbr dswjt 'docker swarm join-token'
abbr dswl 'docker swarm leave'
# nodes
abbr dno 'docker node'
abbr dnoi 'docker node inspect'
abbr dnols 'docker node ls'
abbr dnops 'docker node ps'
abbr dnorm 'docker node rm'
abbr dnou 'docker node update'
abbr dnopr 'docker node promote'
abbr dnode 'docker node demote'
# configs
abbr dcfg 'docker config'
abbr dcfgc 'docker config create'
abbr dcfgi 'docker config inspect'
abbr dcfgls 'docker config ls'
abbr dcfgrm 'docker config rm'
# secrets
abbr dsrt 'docker secret'
abbr dsrtc 'docker secret create'
abbr dsrti 'docker secret inspect'
abbr dsrtls 'docker secret ls'
abbr dsrtrm 'docker secret rm'

abbr dsy 'docker system'
abbr dsydf 'docker system df'
abbr dsydfv 'docker system df -v'
abbr dsyi (grcify 'docker system info')
abbr dsypr 'docker system prune'

# events from a time range - formatted as table
abbr dsye_tr_table 'docker system events --since 10m --until 0m --format "{{json .}}" | jq "[( .id[0:10] // .Actor.ID ),.Type, .Action] | @csv " -r | column -t -s''","''  '
# last 10 mins, use 10h for hours
# --since and --until can be date times formatted like --since "2021-10-30T07:30" --until "2021-10-30T9:00"
# // in jq is like a null coalesce
# .Actor.ID might need limited too in some cases with .Actor.ID[0:30] like I did with 10 and .id... for now just trunc id which is always distracting to see it all even if room
# column -t for table, -s is separator and if I use -s'","' then it strips quote delimited CSVs\! or at least works for me as jq pipes out @csv as double quote delimited

abbr dv 'docker volume' # useful for expanding this alias to then use sub commands, i.e. "dv[space]"
abbr dvls (grcify 'docker volume ls')
abbr dvlsd (grcify 'docker volume ls -f=dangling=true')
abbr dvc 'docker volume create'
abbr dvrm 'docker volume rm'
abbr dvpr 'docker volume prune'
abbr dvi 'docker volume inspect'

abbr dver (grcify 'docker version')

abbr dc 'docker container'
abbr dca 'docker container attach'
abbr dcc 'docker container commit'
abbr dccp 'docker container cp'
abbr dccreate 'docker container create' # full subcommand inclusion implies not likely to use as often (thus longer to type/tab complete)
abbr dcd 'docker container diff'
abbr dce 'docker container exec -i -t '
abbr dcexport 'docker container export'
abbr dci 'docker container inspect'
abbr dck 'docker container kill'
abbr dcl 'docker container logs'
abbr dcpause 'docker container pause'
abbr dcport 'docker container port'
abbr dcpr 'docker container prune'
abbr dcps (grcify 'docker container ps')
abbr dcpsa (grcify 'docker container ps -a')
abbr dcpsm 'docker container ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Mounts}}"' # add mounts
abbr dcr 'docker container run --name'
abbr dcrename 'docker container rename'
abbr dcrestart 'docker container restart'
abbr dcri 'docker container run -i -t --rm ' # favorite
abbr dcrie 'docker container run -i -t --rm --entrypoint '
abbr dcrpriv 'docker container run -i -t --rm --privileged --pid host ubuntu nsenter -t 1 -a' #  ==> all ns of PID 1
abbr dcrm 'docker container rm -f'
abbr dcstart 'docker container start'
abbr dcstats 'docker container stats'
abbr dcstop 'docker container stop'
abbr dct 'docker container top'
abbr dcunpause 'docker container unpause'
abbr dcupdate 'docker container update'
abbr dcwait 'docker container wait'

abbr di 'docker image'
#
abbr dbx 'docker buildx'
abbr dbxls (grcify 'docker buildx ls')
abbr dbxb 'docker buildx build'
abbr dbxba 'docker buildx bake'
abbr dbxc 'docker buildx create'
abbr dbxrm 'docker buildx rm'
abbr dbxdu 'docker buildx du'
abbr dbxi 'docker buildx inspect'
abbr dbxpr 'docker buildx prune'
abbr dbxst 'docker buildx stop'
abbr dbxu 'docker buildx use'
abbr dbxv 'docker buildx version'

abbr dbxit 'docker buildx imagetools'
#
abbr dib 'docker image build'
#
abbr dih 'docker image history --no-trunc'
abbr dihj 'docker image history --no-trunc --format "{{json .}}" | jq'
#
abbr dii 'docker image inspect'
#
abbr dils (grcify 'docker image ls')
abbr dilsa (grcify 'docker image ls --all')
abbr dilsj (grcify 'docker image ls --format "{{json .}}" | jq')
abbr dilsaj 'docker image ls --all --format "{{json .}}" | jq'
abbr dilsdf "docker image ls --format '{{.Size}}\t{{.Repository}}:{{.Tag}}' | sort -h" # for cleanup, sort by size and show `size repo:tag`
#
abbr dipr 'docker image prune'
abbr dipull 'docker image pull'
abbr dipush 'docker image push'
abbr dirm 'docker image rm'
abbr dit 'docker image tag'

abbr dm 'docker manifest'
abbr dmi 'docker manifest inspect'

# * dn reclaimed for `dotnet`, use `dne` for docker network, `dno` for docker node
abbr dne 'docker network'
abbr dnec 'docker network connect'
abbr dned 'docker network disconnect'
abbr dnei 'docker network inspect'
abbr dnels (grcify 'docker network ls')
abbr dnepr 'docker network prune'
abbr dnerm 'docker network rm'

abbr dx 'docker context'
abbr dxls 'docker context ls'
abbr dxu 'docker context use'
abbr dxud 'docker context use default'
abbr dxi 'docker context inspect'
abbr dxc 'docker context create'
abbr dxrm 'docker context rm'
abbr dxs 'docker context show'

# DOCKER COMPOSE:
abbr dco 'docker compose'
abbr dcob 'docker compose build --pull'
abbr dcoc 'docker compose config'
abbr dcocp 'docker compose cp'
#
# down:
#  --remove-orphans includes one-off `dco run` containers
abbr dcod 'docker compose down --remove-orphans'
abbr dcodd 'docker compose down --remove-orphans --dry-run'
abbr dcoda 'docker compose down --remove-orphans --rmi local --volumes'
abbr dcodad 'docker compose down --remove-orphans --rmi local --volumes --dry-run'
# --volumes => rm named + anon, rmi local = built images (not pulled)
#   --rmi all => pulled too
#
abbr dcoe 'docker compose exec'
abbr dcoa 'docker compose attach' # my tiny contribution
abbr dcow 'docker compose watch'
abbr dcoi 'docker compose images'
abbr dcok 'docker compose kill'
abbr dcol 'docker compose logs'
abbr dcolf 'docker compose logs -f'
abbr dcolt 'docker compose logs -f --tail=0'
abbr dcops (grcify 'docker compose ps')
abbr dcopsa (grcify 'docker compose ps -a')
abbr dcols (grcify 'docker compose ls') # * list ALL COMPOSE projets! (not just current dir's project)
abbr dcolsa (grcify 'docker compose ls -a') # stopped too

# # alpha commands
# abbr dcoa 'docker compose alpha'
# abbr dcoviz 'docker compose alpha viz'
# abbr dcopublish 'docker compose alpha publish'



abbr dcopull 'docker compose pull'
abbr dcopush 'docker compose push'
abbr dcorm 'docker compose rm'
#
abbr dcor 'docker compose run --rm' # --rm to cleanup tmp containers else they linger after each run
abbr dcorb 'docker compose run --rm --build'
#
abbr dcore 'docker compose restart'
abbr dcostart 'docker compose start'
abbr dcostop 'docker compose stop'
abbr dcot 'docker compose top'
abbr dcou 'docker compose up'
abbr dcoub 'docker compose up --build'
abbr dcouf 'docker compose up --build --force-recreate --remove-orphans'
abbr dcoud 'docker compose up --detach'
abbr dcouw 'docker compose up --watch' # TBD if I want this abbr (dco ~2.24.7 added --watch)
abbr dcov 'docker compose version'

## dld - docker labs debug: # dld commands are hanging after latest update to DDfM
# abbr dlda 'dld attach'
# abbr dlds 'dld shell'
abbr dd 'docker debug' # in docker desktop 4.27.0+ (appears to be replacing dld is my guess?)
abbr --set-cursor ddc "docker debug --command '%'" # ready to run command in quotes
abbr dde 'docker debug -c entrypoint' # entrypoint inspector (add image/container name/id)

## skopeo
abbr sk skopeo
abbr skh 'skopeo --help'
abbr --set-cursor -- ski 'skopeo --override-os linux inspect docker://%'
abbr --set-cursor -- skim 'skopeo --override-os linux inspect --raw docker://%'
abbr --set-cursor -- skic 'skopeo --override-os linux inspect --config --raw docker://%'
abbr --set-cursor -- skl 'skopeo list-tags docker://docker.io/%'
abbr --set-cursor -- sklm 'skopeo list-tags docker://mcr.microsoft.com/%'

# usage:
#   skopeo list-tags docker://weshigbee/oci-test
#   skopeo inspect docker://weshigbee/oci-test
# raw manifest:
#   skopeo inspect --raw docker://weshigbee/oci-test
# raw image config:
#   skopeo inspect --config --raw docker://weshigbee/oci-test
#  docs:  https://github.com/containers/skopeo/blob/main/contrib/skopeoimage/README.md

## dive
# alias dive='docker container run -i -t --rm -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive'
# usage: dive <args>
# ie: dive foo # (image)

## *** hub-tool ***
# https://github.com/docker/hub-tool
abbr dh hub-tool
# hub-tool account rate-limiting --verbose
# hub-tool repo ls roboxes
abbr dhr "hub-tool repo ls"
# hub-tool tag ls roboxes/debian12
# add --all b/c paging w/ --sort appears to be sorting of the current page only (effectively client side sort of just the current page)
abbr dht "hub-tool tag ls --sort=name=desc --platforms --all" # sort updated/name[=asc/desc] .. name sort sorts by versions such that :8 is before :8.1 is before :8.1.1 which makes sense (:8 ~= :8 "latest", thats commo
abbr dhtu "hub-tool tag ls --sort=updated=desc --platforms --all" # FYI updated is default, still make it explicit doesn't hurt (ie if this changes)
abbr --set-cursor -- dhtj "hub-tool tag ls --format json % | jq" # fyi json includes --platforms by default # ? or just use pjq abbr instead of | jq and ! set-cursor
abbr dhti "hub-tool tag inspect"

# $ hub-tool help
# Available Commands:
#   account     Manage your account
#   help        Help about any command
#   login       Login to the Hub
#   logout      Logout of the Hub
#   org         Manage organizations
#   repo        Manage repositories
#   tag         Manage tags
#   token       Manage Personal Access Tokens
#   version     Version information about this tool
#
# Flags:
#   -h, --help      help for hub-tool
#       --verbose   Print logs
#       --version   Display the version of this tool

# Available Commands:
complete -c hub-tool --no-files
complete -c hub-tool -a account -d "Manage your account" # todo subs
complete -c hub-tool -a help -d "Help about any command"
complete -c hub-tool -a login -d "Login to the Hub"
complete -c hub-tool -a logout -d "Logout of the Hub"
complete -c hub-tool -a org -d "Manage organizations" # todo subs
complete -c hub-tool -a repo -d "Manage repositories" # todo subs
complete -c hub-tool -a tag -d "Manage tags" # todo subs: inspect,ls,rm
complete -c hub-tool -a token -d "Manage Personal Access Tokens" # todo subs
complete -c hub-tool -a version -d "Version information about this tool"
# Flags:  (global)
complete -c hub-tool --long-option help --short-option h --description "help for hub-tool"
complete -c hub-tool --long-option verbose --description "Print logs"
complete -c hub-tool --long-option version --description "Display the version of this tool"






# FYI hub APIs:
# check docker/hub-tool source for endpoints
# allows public access
# or just use --format json with hub-tool commands to likely get same data
# tags https://hub.docker.com/v2/repositories/weshigbee/swarmgs2-echo/tags
# repos https://hub.docker.com/v2/repositories/weshigbee/
# repo details https://hub.docker.com/v2/repositories/weshigbee/swarmgs2-echo
