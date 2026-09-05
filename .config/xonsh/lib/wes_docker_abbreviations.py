"""Generated from fish/load_last_interactive_only/docker-specific.fish."""

from __future__ import annotations

from wes_abbreviations import abbr


def register_docker_abbreviations():
    abbr('din', 'docker inspect')  # Fish line 13
    abbr('dmo', 'docker model')  # Fish line 16
    abbr('dmols', 'docker model list')  # Fish line 17
    abbr('dmoi', 'docker model inspect')  # Fish line 18
    abbr('dmol', 'docker model logs')  # Fish line 19
    abbr('dmopull', 'docker model pull')  # Fish line 20
    abbr('dmopush', 'docker model push')  # Fish line 21
    abbr('dmor', 'docker model run')  # Fish line 22
    abbr('dmorm', 'docker model rm')  # Fish line 23
    abbr('dmot', 'docker model tag')  # Fish line 24
    abbr('dmost', 'docker model status')  # Fish line 25
    abbr('dmov', 'docker model version')  # Fish line 26
    abbr('dst', 'docker stack')  # Fish line 29
    abbr('dstd', 'docker stack deploy -c')  # Fish line 30
    abbr('dstls', 'docker stack ls')  # Fish line 31
    abbr('dstps', 'docker stack ps')  # Fish line 32
    abbr('dstrm', 'docker stack rm')  # Fish line 33
    abbr('dsts', 'docker stack services')  # Fish line 34
    abbr('dse', 'docker service')  # Fish line 36
    abbr('dsec', 'docker service create')  # Fish line 37
    abbr('dsei', 'docker service inspect')  # Fish line 38
    abbr('dsel', 'docker service logs')  # Fish line 39
    abbr('dsels', 'docker service ls')  # Fish line 40
    abbr('dseps', 'docker service ps')  # Fish line 41
    abbr('dserm', 'docker service rm')  # Fish line 42
    abbr('dserb', 'docker service rollback')  # Fish line 43
    abbr('dses', 'docker service scale')  # Fish line 44
    abbr('dseu', 'docker service update')  # Fish line 45
    abbr('dseuf', 'docker service update --force')  # Fish line 46
    abbr('dsw', 'docker swarm')  # Fish line 48
    abbr('dswi', 'docker swarm init')  # Fish line 49
    abbr('dswj', 'docker swarm join')  # Fish line 50
    abbr('dswjt', 'docker swarm join-token')  # Fish line 51
    abbr('dswl', 'docker swarm leave')  # Fish line 52
    abbr('dno', 'docker node')  # Fish line 54
    abbr('dnoi', 'docker node inspect')  # Fish line 55
    abbr('dnols', 'docker node ls')  # Fish line 56
    abbr('dnops', 'docker node ps')  # Fish line 57
    abbr('dnorm', 'docker node rm')  # Fish line 58
    abbr('dnou', 'docker node update')  # Fish line 59
    abbr('dnopr', 'docker node promote')  # Fish line 60
    abbr('dnode', 'docker node demote')  # Fish line 61
    abbr('dcfg', 'docker config')  # Fish line 63
    abbr('dcfgc', 'docker config create')  # Fish line 64
    abbr('dcfgi', 'docker config inspect')  # Fish line 65
    abbr('dcfgls', 'docker config ls')  # Fish line 66
    abbr('dcfgrm', 'docker config rm')  # Fish line 67
    abbr('dsrt', 'docker secret')  # Fish line 69
    abbr('dsrtc', 'docker secret create')  # Fish line 70
    abbr('dsrti', 'docker secret inspect')  # Fish line 71
    abbr('dsrtls', 'docker secret ls')  # Fish line 72
    abbr('dsrtrm', 'docker secret rm')  # Fish line 73
    abbr('dsy', 'docker system')  # Fish line 75
    abbr('dsydf', 'docker system df')  # Fish line 76
    abbr('dsydfv', 'docker system df -v')  # Fish line 77
    abbr('dsyi', 'docker system info')  # Fish line 78
    abbr('dsypr', 'docker system prune')  # Fish line 79
    abbr('dsye_tr_table', 'docker system events --since 10m --until 0m --format "{{json .}}" | jq "[( .id[0:10] // .Actor.ID ),.Type, .Action] | @csv " -r | column -t -s","  ')  # Fish line 82
    abbr('dv', 'docker volume')  # Fish line 89
    abbr('dvls', 'docker volume ls')  # Fish line 90
    abbr('dvlsd', 'docker volume ls -f=dangling=true')  # Fish line 91
    abbr('dvc', 'docker volume create')  # Fish line 92
    abbr('dvrm', 'docker volume rm')  # Fish line 93
    abbr('dvpr', 'docker volume prune')  # Fish line 94
    abbr('dvi', 'docker volume inspect')  # Fish line 95
    abbr('dver', 'docker version')  # Fish line 97
    abbr('dc', 'docker container')  # Fish line 99
    abbr('dca', 'docker container attach')  # Fish line 100
    abbr('dcc', 'docker container commit')  # Fish line 101
    abbr('dccp', 'docker container cp')  # Fish line 102
    abbr('dccreate', 'docker container create')  # Fish line 103
    abbr('dcd', 'docker container diff')  # Fish line 104
    abbr('dce', 'docker container exec -i -t ')  # Fish line 105
    abbr('dcexport', 'docker container export')  # Fish line 106
    abbr('dci', 'docker container inspect')  # Fish line 107
    abbr('dck', 'docker container kill')  # Fish line 108
    abbr('dcl', 'docker container logs')  # Fish line 109
    abbr('dcpause', 'docker container pause')  # Fish line 110
    abbr('dcport', 'docker container port')  # Fish line 111
    abbr('dcpr', 'docker container prune')  # Fish line 112
    abbr('dcps', 'docker container ps')  # Fish line 113
    abbr('dcpsa', 'docker container ps -a')  # Fish line 114
    abbr('dcpsm', 'docker container ps --format "table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Mounts}}"')  # Fish line 115
    abbr('dcr', 'docker container run --name')  # Fish line 116
    abbr('dcrename', 'docker container rename')  # Fish line 117
    abbr('dcrestart', 'docker container restart')  # Fish line 118
    abbr('dcri', 'docker container run -i -t --rm ')  # Fish line 119
    abbr('dcrie', 'docker container run -i -t --rm --entrypoint ')  # Fish line 120
    abbr('dcrpriv', 'docker container run -i -t --rm --privileged --pid host ubuntu nsenter -t 1 -a')  # Fish line 121
    abbr('dcrm', 'docker container rm -f')  # Fish line 122
    abbr('dcstart', 'docker container start')  # Fish line 123
    abbr('dcstats', 'docker container stats')  # Fish line 124
    abbr('dcstop', 'docker container stop')  # Fish line 125
    abbr('dct', 'docker container top')  # Fish line 126
    abbr('dcunpause', 'docker container unpause')  # Fish line 127
    abbr('dcupdate', 'docker container update')  # Fish line 128
    abbr('dcwait', 'docker container wait')  # Fish line 129
    abbr('di', 'docker image')  # Fish line 131
    abbr('dbx', 'docker buildx')  # Fish line 133
    abbr('dbxls', 'docker buildx ls')  # Fish line 134
    abbr('dbxb', 'docker buildx build')  # Fish line 135
    abbr('dbxba', 'docker buildx bake')  # Fish line 136
    abbr('dbxc', 'docker buildx create')  # Fish line 137
    abbr('dbxrm', 'docker buildx rm')  # Fish line 138
    abbr('dbxdu', 'docker buildx du')  # Fish line 139
    abbr('dbxi', 'docker buildx inspect')  # Fish line 140
    abbr('dbxpr', 'docker buildx prune')  # Fish line 141
    abbr('dbxst', 'docker buildx stop')  # Fish line 142
    abbr('dbxu', 'docker buildx use')  # Fish line 143
    abbr('dbxv', 'docker buildx version')  # Fish line 144
    abbr('dbxit', 'docker buildx imagetools')  # Fish line 146
    abbr('dib', 'docker image build')  # Fish line 148
    abbr('dih', 'docker image history --no-trunc')  # Fish line 150
    abbr('dihj', 'docker image history --no-trunc --format "{{json .}}" | jq')  # Fish line 151
    abbr('dii', 'docker image inspect')  # Fish line 153
    abbr('dils', 'docker image ls')  # Fish line 155
    abbr('dilsa', 'docker image ls --all')  # Fish line 156
    abbr('dilsj', 'docker image ls --format "{{json .}}" | jq')  # Fish line 157
    abbr('dilsaj', 'docker image ls --all --format "{{json .}}" | jq')  # Fish line 158
    abbr('dilsdf', "docker image ls --format '{{.Size}}\\t{{.Repository}}:{{.Tag}}' | sort -h")  # Fish line 159
    abbr('dipr', 'docker image prune')  # Fish line 161
    abbr('dipull', 'docker image pull')  # Fish line 162
    abbr('dipush', 'docker image push')  # Fish line 163
    abbr('dirm', 'docker image rm')  # Fish line 164
    abbr('dit', 'docker image tag')  # Fish line 165
    abbr('dm', 'docker manifest')  # Fish line 167
    abbr('dmi', 'docker manifest inspect')  # Fish line 168
    abbr('dne', 'docker network')  # Fish line 171
    abbr('dnec', 'docker network connect')  # Fish line 172
    abbr('dned', 'docker network disconnect')  # Fish line 173
    abbr('dnei', 'docker network inspect')  # Fish line 174
    abbr('dnels', 'docker network ls')  # Fish line 175
    abbr('dnepr', 'docker network prune')  # Fish line 176
    abbr('dnerm', 'docker network rm')  # Fish line 177
    abbr('dx', 'docker context')  # Fish line 179
    abbr('dxls', 'docker context ls')  # Fish line 180
    abbr('dxu', 'docker context use')  # Fish line 181
    abbr('dxud', 'docker context use default')  # Fish line 182
    abbr('dxi', 'docker context inspect')  # Fish line 183
    abbr('dxc', 'docker context create')  # Fish line 184
    abbr('dxrm', 'docker context rm')  # Fish line 185
    abbr('dxs', 'docker context show')  # Fish line 186
    abbr('dco', 'docker compose')  # Fish line 189
    abbr('dcob', 'docker compose build --pull')  # Fish line 190
    abbr('dcoc', 'docker compose config')  # Fish line 191
    abbr('dcocp', 'docker compose cp')  # Fish line 192
    abbr('dcod', 'docker compose down --remove-orphans')  # Fish line 196
    abbr('dcodd', 'docker compose down --remove-orphans --dry-run')  # Fish line 197
    abbr('dcoda', 'docker compose down --remove-orphans --rmi local --volumes')  # Fish line 198
    abbr('dcodad', 'docker compose down --remove-orphans --rmi local --volumes --dry-run')  # Fish line 199
    abbr('dcoe', 'docker compose exec')  # Fish line 203
    abbr('dcoa', 'docker compose attach')  # Fish line 204
    abbr('dcow', 'docker compose watch')  # Fish line 205
    abbr('dcoi', 'docker compose images')  # Fish line 206
    abbr('dcok', 'docker compose kill')  # Fish line 207
    abbr('dcol', 'docker compose logs')  # Fish line 208
    abbr('dcolf', 'docker compose logs -f')  # Fish line 209
    abbr('dcolt', 'docker compose logs -f --tail=0')  # Fish line 210
    abbr('dcops', 'docker compose ps')  # Fish line 211
    abbr('dcopsa', 'docker compose ps -a')  # Fish line 212
    abbr('dcols', 'docker compose ls')  # Fish line 213
    abbr('dcolsa', 'docker compose ls -a')  # Fish line 214
    abbr('dcopull', 'docker compose pull')  # Fish line 221
    abbr('dcopush', 'docker compose push')  # Fish line 222
    abbr('dcorm', 'docker compose rm')  # Fish line 223
    abbr('dcor', 'docker compose run --rm')  # Fish line 225
    abbr('dcorb', 'docker compose run --rm --build')  # Fish line 226
    abbr('dcore', 'docker compose restart')  # Fish line 228
    abbr('dcostart', 'docker compose start')  # Fish line 229
    abbr('dcostop', 'docker compose stop')  # Fish line 230
    abbr('dcot', 'docker compose top')  # Fish line 231
    abbr('dcou', 'docker compose up')  # Fish line 232
    abbr('dcoub', 'docker compose up --build')  # Fish line 233
    abbr('dcouf', 'docker compose up --build --force-recreate --remove-orphans')  # Fish line 234
    abbr('dcoud', 'docker compose up --detach')  # Fish line 235
    abbr('dcouw', 'docker compose up --watch')  # Fish line 236
    abbr('dcov', 'docker compose version')  # Fish line 237
    abbr('dd', 'docker debug')  # Fish line 242
    abbr('ddc', "docker debug --command '%'", cursor_marker="%")  # Fish line 243
    abbr('dde', 'docker debug -c entrypoint')  # Fish line 244
    abbr('sk', 'skopeo')  # Fish line 247
    abbr('skh', 'skopeo --help')  # Fish line 248
    abbr('ski', 'skopeo --override-os linux inspect docker://%', cursor_marker="%")  # Fish line 249
    abbr('skim', 'skopeo --override-os linux inspect --raw docker://%', cursor_marker="%")  # Fish line 250
    abbr('skic', 'skopeo --override-os linux inspect --config --raw docker://%', cursor_marker="%")  # Fish line 251
    abbr('skl', 'skopeo list-tags docker://docker.io/%', cursor_marker="%")  # Fish line 252
    abbr('sklm', 'skopeo list-tags docker://mcr.microsoft.com/%', cursor_marker="%")  # Fish line 253
    abbr('dh', 'hub-tool')  # Fish line 271
    abbr('dhr', 'hub-tool repo ls')  # Fish line 274
    abbr('dht', 'hub-tool tag ls --sort=name=desc --platforms --all')  # Fish line 277
    abbr('dhtu', 'hub-tool tag ls --sort=updated=desc --platforms --all')  # Fish line 278
    abbr('dhtj', 'hub-tool tag ls --format json % | jq', cursor_marker="%")  # Fish line 279
    abbr('dhti', 'hub-tool tag inspect')  # Fish line 280
