
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
ealias dilsaj='docker image ls --all --format "{{json .}} | jq'
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
prefix=dco
ealias ${prefix}='docker compose'
ealias ${prefix}b='docker compose build --pull'
ealias ${prefix}c='docker compose config'
ealias ${prefix}cp='docker compose cp'
#
# down:
local _down='docker compose down --remove-orphans' #  --remove-orphans includes one-off `dco run` containers
ealias ${prefix}d="${_down}"
ealias ${prefix}dd="${_down} --dry-run"
ealias ${prefix}da="${_down} --rmi local --volumes"
ealias ${prefix}dad="${_down} --rmi local --volumes --dry-run"
# --volumes => rm named + anon, rmi local = built images (not pulled)
#   --rmi all => pulled too
#
ealias ${prefix}e='docker compose exec'
ealias ${prefix}i='docker compose images'
ealias ${prefix}k='docker compose kill'
ealias ${prefix}l='docker compose logs'
ealias ${prefix}lf='docker compose logs -f'
ealias ${prefix}lt='docker compose logs -f --tail=0'
ealias ${prefix}ps='grc docker compose ps'
ealias ${prefix}psa='grc docker compose ps -a'
ealias ${prefix}ls='grc docker compose ls' # * list ALL COMPOSE projets! (not just current dir's project)
ealias ${prefix}lsa='grc docker compose ls -a' # stopped too

# # alpha commands
# ealias ${prefix}a='docker compose alpha'
# ealias ${prefix}v='docker compose alpha viz'

ealias ${prefix}w='docker compose watch'

ealias ${prefix}pull='docker compose pull'
ealias ${prefix}push='docker compose push'
ealias ${prefix}rm='docker compose rm'
ealias ${prefix}r='docker compose run --rm' # --rm to cleanup tmp containers else they linger after each run
ealias ${prefix}re='docker compose restart'
ealias ${prefix}start='docker compose start'
ealias ${prefix}stop='docker compose stop'
ealias ${prefix}t='docker compose top'
ealias ${prefix}u='docker compose up'
ealias ${prefix}uf='docker compose up --force-recreate --remove-orphans'
ealias ${prefix}ud='docker compose up --detach'
ealias ${prefix}v='docker compose version'



## dld - docker labs debug:
ealias dlda='dld attach'
ealias dlds='dld shell'
