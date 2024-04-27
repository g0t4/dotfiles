
$env:DOCKER_HIDE_LEGACY_COMMANDS=1 # less clutter in help output

ealias din 'docker inspect'

ealias dsy 'docker system'
ealias dsydf 'docker system df'
ealias dsydfv 'docker system df -v'
ealias dsyi 'docker system info'
ealias dsypr 'docker system prune'


ealias dv 'docker volume' # useful for expanding this alias to then use sub commands, i.e. "dv[space]"
ealias dvls 'docker volume ls'
ealias dvlsd 'docker volume ls -f=dangling=true'
ealias dvc 'docker volume create'
ealias dvrm 'docker volume rm'
ealias dvpr 'docker volume prune'
ealias dvi 'docker volume inspect'

ealias dver 'docker version'

ealias dc 'docker container'
ealias dca 'docker container attach'
ealias dcc 'docker container commit'
ealias dccp 'docker container cp'
ealias dcd 'docker container diff'
ealias dce 'docker container exec -i -t '
ealias dci 'docker container inspect'
ealias dck 'docker container kill'
ealias dcl 'docker container logs'

# listing containers
ealias dcps 'docker container ps'
ealias dcpsa 'docker container ps -a'
ealias dcpsm 'docker container ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Mounts}}"' # add mounts

ealias dcpr 'docker container prune'
ealias dcrm 'docker container rm -f'

# favorites:
ealias dcri 'docker container run -i -t --rm '
ealias dcrie 'docker container run -i -t --rm --entrypoint '
ealias dcr 'docker container run --name'
ealias dct 'docker container top'

ealias di 'docker image'
#
ealias dbx 'docker buildx'
ealias dbxls 'docker buildx ls'
ealias dbxb 'docker buildx build'
ealias dbxba 'docker buildx bake'
ealias dbxc 'docker buildx create'
ealias dbxrm 'docker buildx rm'
ealias dbxdu 'docker buildx du'
ealias dbxi 'docker buildx inspect'
ealias dbxpr 'docker buildx prune'
ealias dbxst 'docker buildx stop'
ealias dbxu 'docker buildx use'
ealias dbxv 'docker buildx version'

ealias dbxit 'docker buildx imagetools'
#
ealias dib 'docker image build'
#
ealias dih 'docker image history --no-trunc'
ealias dihj 'docker image history --no-trunc --format "{{json .}}" | jq -C'
#
ealias dii 'docker image inspect'
#
ealias dils 'docker image ls'
ealias dilsa 'docker image ls --all'
ealias dilsj 'docker image ls --format "{{json .}}" | jq -C'
ealias dilsaj 'docker image ls --all --format "{{json .}} | jq -C'
#
ealias dipr 'docker image prune'
ealias dipull 'docker image pull'
ealias dipush 'docker image push'
ealias dirm 'docker image rm'
ealias dit 'docker image tag'

ealias dm 'docker manifest'
ealias dmi 'docker manifest inspect'


# * dn reclaimed for `dotnet`, use `dne` for docker network, `dno` for docker node
ealias dne 'docker network'
ealias dnec 'docker network connect'
ealias dned 'docker network disconnect'
ealias dnei 'docker network inspect'
ealias dnels 'docker network ls'
ealias dnepr 'docker network prune'
ealias dnerm 'docker network rm'

ealias dx 'docker context'
ealias dxls 'docker context ls'
ealias dxu 'docker context use'
ealias dxud 'docker context use default'
ealias dxi 'docker context inspect'
ealias dxc 'docker context create'
ealias dxrm 'docker context rm'
ealias dxs 'docker context show'


# DOCKER COMPOSE:
$prefix='dco'
ealias ${prefix} 'docker compose'
ealias ${prefix}b 'docker compose build --pull'
ealias ${prefix}c 'docker compose config'
ealias ${prefix}cp 'docker compose cp'
#
# down:
$_dco_down='docker compose down --remove-orphans' #  --remove-orphans includes one-off `dco run` containers
ealias ${prefix}d "${_dco_down}"
ealias ${prefix}dd "${_dco_down} --dry-run"
ealias ${prefix}da "${_dco_down} --rmi local --volumes"
ealias ${prefix}dad "${_dco_down} --rmi local --volumes --dry-run"
# --volumes => rm named + anon, rmi local = built images (not pulled)
#   --rmi all => pulled too
#
ealias ${prefix}e 'docker compose exec'
ealias ${prefix}i 'docker compose images'
ealias ${prefix}k 'docker compose kill'
ealias ${prefix}l 'docker compose logs'
ealias ${prefix}lf 'docker compose logs -f'
ealias ${prefix}lt 'docker compose logs -f --tail=0'
ealias ${prefix}ps 'grc docker compose ps'
ealias ${prefix}psa 'grc docker compose ps -a'
ealias ${prefix}ls 'grc docker compose ls' # * list ALL COMPOSE projets! (not just current dir's project)
ealias ${prefix}lsa 'grc docker compose ls -a' # stopped too

# # alpha commands
# ealias ${prefix}a 'docker compose alpha'
# ealias ${prefix}v 'docker compose alpha viz'

ealias ${prefix}w 'docker compose watch'

ealias ${prefix}pull 'docker compose pull'
ealias ${prefix}push 'docker compose push'
ealias ${prefix}rm 'docker compose rm'
#
ealias ${prefix}r 'docker compose run --rm' # --rm to cleanup tmp containers else they linger after each run
ealias ${prefix}rb 'docker compose run --build --rm'
#
ealias ${prefix}re 'docker compose restart'
ealias ${prefix}start 'docker compose start'
ealias ${prefix}stop 'docker compose stop'
ealias ${prefix}t 'docker compose top'
ealias ${prefix}u 'docker compose up'
ealias ${prefix}uf 'docker compose up --force-recreate --remove-orphans'
ealias ${prefix}ud 'docker compose up --detach'
ealias ${prefix}v 'docker compose version'



## dld - docker labs debug:
ealias dlda 'dld attach'
ealias dlds 'dld shell'
