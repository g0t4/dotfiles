# FYI using ealias added 25+ms to fish startup for this file alone b/c it had 160 ealiases... abbr alone is 10x faster than ealias
export DOCKER_HIDE_LEGACY_COMMANDS=1 # less clutter in help output

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
abbr dsyi 'grc docker system info'
abbr dsypr 'docker system prune'

# events from a time range - formatted as table
abbr dsye_tr_table 'docker system events --since 10m --until 0m --format "{{json .}}" | jq "[( .id[0:10] // .Actor.ID ),.Type, .Action] | @csv " -r | column -t -s''","''  '
    # last 10 mins, use 10h for hours
    # --since and --until can be date times formatted like --since "2021-10-30T07:30" --until "2021-10-30T9:00"
    # // in jq is like a null coalesce
    # .Actor.ID might need limited too in some cases with .Actor.ID[0:30] like I did with 10 and .id... for now just trunc id which is always distracting to see it all even if room
    # column -t for table, -s is separator and if I use -s'","' then it strips quote delimited CSVs\! or at least works for me as jq pipes out @csv as double quote delimited

abbr dv 'docker volume' # useful for expanding this alias to then use sub commands, i.e. "dv[space]"
abbr dvls 'grc docker volume ls'
abbr dvlsd 'grc docker volume ls -f=dangling=true'
abbr dvc 'docker volume create'
abbr dvrm 'docker volume rm'
abbr dvpr 'docker volume prune'
abbr dvi 'docker volume inspect'

abbr dver 'grc docker version'

abbr dc 'docker container'
abbr dca 'docker container attach'
abbr dcc 'docker container commit'
abbr dccp 'docker container cp'
abbr dcd 'docker container diff'
abbr dce 'docker container exec -i -t '
abbr dci 'docker container inspect'
abbr dck 'docker container kill'
abbr dcl 'docker container logs'

# listing containers
abbr dcps 'grc docker container ps'
abbr dcpsa 'grc docker container ps -a'
abbr dcpsm 'docker container ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Mounts}}"' # add mounts

abbr dcpr 'docker container prune'
abbr dcrm 'docker container rm -f'

# favorites:
abbr dcri 'docker container run -i -t --rm '
abbr dcrie 'docker container run -i -t --rm --entrypoint '
abbr dcr 'docker container run --name'
abbr dct 'docker container top'

abbr di 'docker image'
#
abbr dbx 'docker buildx'
abbr dbxls 'grc docker buildx ls'
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
abbr dils 'grc docker image ls'
abbr dilsa 'grc docker image ls --all'
abbr dilsj 'grc docker image ls --format "{{json .}}" | jq'
abbr dilsaj 'docker image ls --all --format "{{json .}}" | jq'
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
abbr dnels 'grc docker network ls'
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
abbr dcops 'grc docker compose ps'
abbr dcopsa 'grc docker compose ps -a'
abbr dcols 'grc docker compose ls' # * list ALL COMPOSE projets! (not just current dir's project)
abbr dcolsa 'grc docker compose ls -a' # stopped too

# # alpha commands
# abbr dcoa 'docker compose alpha'
# abbr dcoviz 'docker compose alpha viz'
# abbr dcopublish 'docker compose alpha publish'



abbr dcopull 'docker compose pull'
abbr dcopush 'docker compose push'
abbr dcorm 'docker compose rm'
abbr dcor 'docker compose run --rm' # --rm to cleanup tmp containers else they linger after each run
abbr dcore 'docker compose restart'
abbr dcostart 'docker compose start'
abbr dcostop 'docker compose stop'
abbr dcot 'docker compose top'
abbr dcou 'docker compose up'
abbr dcouf 'docker compose up --force-recreate --remove-orphans'
abbr dcoud 'docker compose up --detach'
abbr dcov 'docker compose version'

## dld - docker labs debug: # dld commands are hanging after latest update to DDfM
# abbr dlda 'dld attach'
# abbr dlds 'dld shell'
abbr dd 'docker debug' # in docker desktop 4.27.0+ (appears to be replacing dld is my guess?)
abbr --set-cursor='!' ddc "docker debug --command '!'" # ready to run command in quotes
abbr dde 'docker debug -c entrypoint' # entrypoint inspector (add image/container name/id)

## skopeo
abbr sk 'skopeo'
abbr skh 'skopeo --help'
abbr ski 'skopeo --override-os linux inspect docker://' --NoSpaceAfter
abbr skim 'skopeo --override-os linux inspect --raw docker://' --NoSpaceAfter
abbr skic 'skopeo --override-os linux inspect --config --raw docker://' --NoSpaceAfter
abbr skl 'skopeo list-tags docker://docker.io/' --NoSpaceAfter
abbr sklm 'skopeo list-tags docker://mcr.microsoft.com/' --NoSpaceAfter

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