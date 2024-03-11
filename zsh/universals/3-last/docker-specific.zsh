export DOCKER_HIDE_LEGACY_COMMANDS=1 # less clutter in help output

ealias din='docker inspect'

# stack
ealias dst='docker stack'
ealias dstd='docker stack deploy -c'
ealias dstls='docker stack ls'
ealias dstps='docker stack ps'
ealias dstrm='docker stack rm'
ealias dsts='docker stack services'
# service
ealias dse='docker service'
ealias dsec='docker service create'
ealias dsei='docker service inspect'
ealias dsel='docker service logs'
ealias dsels='docker service ls'
ealias dseps='docker service ps'
ealias dserm='docker service rm'
ealias dserb='docker service rollback'
ealias dses='docker service scale'
ealias dseu='docker service update'
ealias dseuf='docker service update --force'
# swarm
ealias dsw='docker swarm'
ealias dswi='docker swarm init'
ealias dswj='docker swarm join'
ealias dswjt='docker swarm join-token'
ealias dswl='docker swarm leave'
# nodes
ealias dno='docker node'
ealias dnoi='docker node inspect'
ealias dnols='docker node ls'
ealias dnops='docker node ps'
ealias dnorm='docker node rm'
ealias dnou='docker node update'
ealias dnopr='docker node promote'
ealias dnode='docker node demote'
# configs
ealias dcfg='docker config'
ealias dcfgc='docker config create'
ealias dcfgi='docker config inspect'
ealias dcfgls='docker config ls'
ealias dcfgrm='docker config rm'
# secrets
ealias dsrt='docker secret'
ealias dsrtc='docker secret create'
ealias dsrti='docker secret inspect'
ealias dsrtls='docker secret ls'
ealias dsrtrm='docker secret rm'

ealias dsy='docker system'
ealias dsydf='docker system df'
ealias dsydfv='docker system df -v'
ealias dsyi='grc docker system info'
ealias dsypr='docker system prune'

# events from a time range - formatted as table
ealias dsye_tr_table='docker system events --since 10m --until 0m --format "{{json .}}" | jq "[( .id[0:10] // .Actor.ID ),.Type, .Action] | @csv " -r | column -t -s''","''  '
    # last 10 mins, use 10h for hours
    # --since and --until can be date times formatted like --since "2021-10-30T07:30" --until "2021-10-30T9:00"
    # // in jq is like a null coalesce
    # .Actor.ID might need limited too in some cases with .Actor.ID[0:30] like I did with 10 and .id... for now just trunc id which is always distracting to see it all even if room
    # column -t for table, -s is separator and if I use -s'","' then it strips quote delimited CSVs\! or at least works for me as jq pipes out @csv as double quote delimited

ealias dv='docker volume' # useful for expanding this alias to then use sub commands, i.e. "dv[space]"
ealias dvls='grc docker volume ls'
ealias dvlsd='grc docker volume ls -f=dangling=true'
ealias dvc='docker volume create'
ealias dvrm='docker volume rm'
ealias dvpr='docker volume prune'
ealias dvi='docker volume inspect'

ealias dver='grc docker version'

ealias dc='docker container'
ealias dca='docker container attach'
ealias dcc='docker container commit'
ealias dccp='docker container cp'
ealias dcd='docker container diff'
ealias dce='docker container exec -i -t '
ealias dci='docker container inspect'
ealias dck='docker container kill'
ealias dcl='docker container logs'

# listing containers
ealias dcps='grc docker container ps'
ealias dcpsa='grc docker container ps -a'
ealias dcpsm='docker container ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Mounts}}"' # add mounts

ealias dcpr='docker container prune'
ealias dcrm='docker container rm -f'

# favorites:
ealias dcri='docker container run -i -t --rm '
ealias dcrie='docker container run -i -t --rm --entrypoint '
ealias dcr='docker container run --name'
ealias dct='docker container top'

ealias di='docker image'
#
ealias dbx='docker buildx'
ealias dbxls='grc docker buildx ls'
ealias dbxb='docker buildx build'
ealias dbxba='docker buildx bake'
ealias dbxc='docker buildx create'
ealias dbxrm='docker buildx rm'
ealias dbxdu='docker buildx du'
ealias dbxi='docker buildx inspect'
ealias dbxpr='docker buildx prune'
ealias dbxst='docker buildx stop'
ealias dbxu='docker buildx use'
ealias dbxv='docker buildx version'

ealias dbxit='docker buildx imagetools'
#
ealias dib='docker image build'
#
ealias dih='docker image history --no-trunc'
ealias dihj='docker image history --no-trunc --format "{{json .}}" | jq'
#
ealias dii='docker image inspect'
#
ealias dils='grc docker image ls'
ealias dilsa='grc docker image ls --all'
ealias dilsj='grc docker image ls --format "{{json .}}" | jq'
ealias dilsaj='docker image ls --all --format "{{json .}}" | jq'
#
ealias dipr='docker image prune'
ealias dipull='docker image pull'
ealias dipush='docker image push'
ealias dirm='docker image rm'
ealias dit='docker image tag'

ealias dm='docker manifest'
ealias dmi='docker manifest inspect'

# * dn reclaimed for `dotnet`, use `dne` for docker network, `dno` for docker node
ealias dne='docker network'
ealias dnec='docker network connect'
ealias dned='docker network disconnect'
ealias dnei='docker network inspect'
ealias dnels='grc docker network ls'
ealias dnepr='docker network prune'
ealias dnerm='docker network rm'

ealias dx='docker context'
ealias dxls='docker context ls'
ealias dxu='docker context use'
ealias dxud='docker context use default'
ealias dxi='docker context inspect'
ealias dxc='docker context create'
ealias dxrm='docker context rm'
ealias dxs='docker context show'

# DOCKER COMPOSE:
ealias dco='docker compose'
ealias dcob='docker compose build --pull'
ealias dcoc='docker compose config'
ealias dcocp='docker compose cp'
#
# down:
#  --remove-orphans includes one-off `dco run` containers
ealias dcod='docker compose down --remove-orphans'
ealias dcodd='docker compose down --remove-orphans --dry-run'
ealias dcoda='docker compose down --remove-orphans --rmi local --volumes'
ealias dcodad='docker compose down --remove-orphans --rmi local --volumes --dry-run'
# --volumes => rm named + anon, rmi local = built images (not pulled)
#   --rmi all => pulled too
#
ealias dcoe='docker compose exec'
ealias dcoa='docker compose attach' # my tiny contribution
ealias dcow='docker compose watch'
ealias dcoi='docker compose images'
ealias dcok='docker compose kill'
ealias dcol='docker compose logs'
ealias dcolf='docker compose logs -f'
ealias dcolt='docker compose logs -f --tail=0'
ealias dcops='grc docker compose ps'
ealias dcopsa='grc docker compose ps -a'
ealias dcols='grc docker compose ls' # * list ALL COMPOSE projets! (not just current dir's project)
ealias dcolsa='grc docker compose ls -a' # stopped too

# # alpha commands
# ealias dcoa='docker compose alpha'
# ealias dcoviz='docker compose alpha viz'
# ealias dcopublish='docker compose alpha publish'



ealias dcopull='docker compose pull'
ealias dcopush='docker compose push'
ealias dcorm='docker compose rm'
ealias dcor='docker compose run --rm' # --rm to cleanup tmp containers else they linger after each run
ealias dcore='docker compose restart'
ealias dcostart='docker compose start'
ealias dcostop='docker compose stop'
ealias dcot='docker compose top'
ealias dcou='docker compose up'
ealias dcouf='docker compose up --force-recreate --remove-orphans'
ealias dcoud='docker compose up --detach'
ealias dcov='docker compose version'

## dld - docker labs debug: # dld commands are hanging after latest update to DDfM
# ealias dlda='dld attach'
# ealias dlds='dld shell'
ealias dd='docker debug' # in docker desktop 4.27.0+ (appears to be replacing dld is my guess?)

## skopeo
ealias sk='skopeo'
ealias skh='skopeo --help'
ealias ski='skopeo --override-os linux inspect docker://' --NoSpaceAfter
ealias skim='skopeo --override-os linux inspect --raw docker://' --NoSpaceAfter
ealias skic='skopeo --override-os linux inspect --config --raw docker://' --NoSpaceAfter
ealias skl='skopeo list-tags docker://docker.io/' --NoSpaceAfter
ealias sklm='skopeo list-tags docker://mcr.microsoft.com/' --NoSpaceAfter

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
abbr dh "hub-tool"
# hub-tool account rate-limiting --verbose
# hub-tool repo ls roboxes
abbr dhr "hub-tool repo ls"
# hub-tool tag ls roboxes/debian12
abbr dht "hub-tool tag ls --sort=name=desc --platforms"
abbr dhtu "hub-tool tag ls --sort=updated=desc --platforms"
aabbr dhtj "hub-tool tag ls --format json" # fyi json includes --platforms by default
abbr dhti "hub-tool tag inspect"

# FYI hub APIs:
# check docker/hub-tool source for endpoints
# allows public access
# or just use --format json with hub-tool commands to likely get same data
# tags https://hub.docker.com/v2/repositories/weshigbee/swarmgs2-echo/tags
# repos https://hub.docker.com/v2/repositories/weshigbee/
# repo details https://hub.docker.com/v2/repositories/weshigbee/swarmgs2-echo