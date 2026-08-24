"""Generated from fish/load_last_interactive_only/docker-specific.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr


def register_docker_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'din', 'docker inspect')  # Fish line 13
    abbr(registry, 'dmo', 'docker model')  # Fish line 16
    abbr(registry, 'dmols', 'docker model list')  # Fish line 17
    abbr(registry, 'dmoi', 'docker model inspect')  # Fish line 18
    abbr(registry, 'dmol', 'docker model logs')  # Fish line 19
    abbr(registry, 'dmopull', 'docker model pull')  # Fish line 20
    abbr(registry, 'dmopush', 'docker model push')  # Fish line 21
    abbr(registry, 'dmor', 'docker model run')  # Fish line 22
    abbr(registry, 'dmorm', 'docker model rm')  # Fish line 23
    abbr(registry, 'dmot', 'docker model tag')  # Fish line 24
    abbr(registry, 'dmost', 'docker model status')  # Fish line 25
    abbr(registry, 'dmov', 'docker model version')  # Fish line 26
    abbr(registry, 'dst', 'docker stack')  # Fish line 29
    abbr(registry, 'dstd', 'docker stack deploy -c')  # Fish line 30
    abbr(registry, 'dstls', 'docker stack ls')  # Fish line 31
    abbr(registry, 'dstps', 'docker stack ps')  # Fish line 32
    abbr(registry, 'dstrm', 'docker stack rm')  # Fish line 33
    abbr(registry, 'dsts', 'docker stack services')  # Fish line 34
    abbr(registry, 'dse', 'docker service')  # Fish line 36
    abbr(registry, 'dsec', 'docker service create')  # Fish line 37
    abbr(registry, 'dsei', 'docker service inspect')  # Fish line 38
    abbr(registry, 'dsel', 'docker service logs')  # Fish line 39
    abbr(registry, 'dsels', 'docker service ls')  # Fish line 40
    abbr(registry, 'dseps', 'docker service ps')  # Fish line 41
    abbr(registry, 'dserm', 'docker service rm')  # Fish line 42
    abbr(registry, 'dserb', 'docker service rollback')  # Fish line 43
    abbr(registry, 'dses', 'docker service scale')  # Fish line 44
    abbr(registry, 'dseu', 'docker service update')  # Fish line 45
    abbr(registry, 'dseuf', 'docker service update --force')  # Fish line 46
    abbr(registry, 'dsw', 'docker swarm')  # Fish line 48
    abbr(registry, 'dswi', 'docker swarm init')  # Fish line 49
    abbr(registry, 'dswj', 'docker swarm join')  # Fish line 50
    abbr(registry, 'dswjt', 'docker swarm join-token')  # Fish line 51
    abbr(registry, 'dswl', 'docker swarm leave')  # Fish line 52
    abbr(registry, 'dno', 'docker node')  # Fish line 54
    abbr(registry, 'dnoi', 'docker node inspect')  # Fish line 55
    abbr(registry, 'dnols', 'docker node ls')  # Fish line 56
    abbr(registry, 'dnops', 'docker node ps')  # Fish line 57
    abbr(registry, 'dnorm', 'docker node rm')  # Fish line 58
    abbr(registry, 'dnou', 'docker node update')  # Fish line 59
    abbr(registry, 'dnopr', 'docker node promote')  # Fish line 60
    abbr(registry, 'dnode', 'docker node demote')  # Fish line 61
    abbr(registry, 'dcfg', 'docker config')  # Fish line 63
    abbr(registry, 'dcfgc', 'docker config create')  # Fish line 64
    abbr(registry, 'dcfgi', 'docker config inspect')  # Fish line 65
    abbr(registry, 'dcfgls', 'docker config ls')  # Fish line 66
    abbr(registry, 'dcfgrm', 'docker config rm')  # Fish line 67
    abbr(registry, 'dsrt', 'docker secret')  # Fish line 69
    abbr(registry, 'dsrtc', 'docker secret create')  # Fish line 70
    abbr(registry, 'dsrti', 'docker secret inspect')  # Fish line 71
    abbr(registry, 'dsrtls', 'docker secret ls')  # Fish line 72
    abbr(registry, 'dsrtrm', 'docker secret rm')  # Fish line 73
    abbr(registry, 'dsy', 'docker system')  # Fish line 75
    abbr(registry, 'dsydf', 'docker system df')  # Fish line 76
    abbr(registry, 'dsydfv', 'docker system df -v')  # Fish line 77
    abbr(registry, 'dsyi', 'docker system info')  # Fish line 78
    abbr(registry, 'dsypr', 'docker system prune')  # Fish line 79
    abbr(registry, 'dsye_tr_table', 'docker system events --since 10m --until 0m --format "{{json .}}" | jq "[( .id[0:10] // .Actor.ID ),.Type, .Action] | @csv " -r | column -t -s","  ')  # Fish line 82
    abbr(registry, 'dv', 'docker volume')  # Fish line 89
    abbr(registry, 'dvls', 'docker volume ls')  # Fish line 90
    abbr(registry, 'dvlsd', 'docker volume ls -f=dangling=true')  # Fish line 91
    abbr(registry, 'dvc', 'docker volume create')  # Fish line 92
    abbr(registry, 'dvrm', 'docker volume rm')  # Fish line 93
    abbr(registry, 'dvpr', 'docker volume prune')  # Fish line 94
    abbr(registry, 'dvi', 'docker volume inspect')  # Fish line 95
    abbr(registry, 'dver', 'docker version')  # Fish line 97
    abbr(registry, 'dc', 'docker container')  # Fish line 99
    abbr(registry, 'dca', 'docker container attach')  # Fish line 100
    abbr(registry, 'dcc', 'docker container commit')  # Fish line 101
    abbr(registry, 'dccp', 'docker container cp')  # Fish line 102
    abbr(registry, 'dccreate', 'docker container create')  # Fish line 103
    abbr(registry, 'dcd', 'docker container diff')  # Fish line 104
    abbr(registry, 'dce', 'docker container exec -i -t ')  # Fish line 105
    abbr(registry, 'dcexport', 'docker container export')  # Fish line 106
    abbr(registry, 'dci', 'docker container inspect')  # Fish line 107
    abbr(registry, 'dck', 'docker container kill')  # Fish line 108
    abbr(registry, 'dcl', 'docker container logs')  # Fish line 109
    abbr(registry, 'dcpause', 'docker container pause')  # Fish line 110
    abbr(registry, 'dcport', 'docker container port')  # Fish line 111
    abbr(registry, 'dcpr', 'docker container prune')  # Fish line 112
    abbr(registry, 'dcps', 'docker container ps')  # Fish line 113
    abbr(registry, 'dcpsa', 'docker container ps -a')  # Fish line 114
    abbr(registry, 'dcpsm', 'docker container ps --format "table {{.ID}}\\t{{.Names}}\\t{{.Image}}\\t{{.Mounts}}"')  # Fish line 115
    abbr(registry, 'dcr', 'docker container run --name')  # Fish line 116
    abbr(registry, 'dcrename', 'docker container rename')  # Fish line 117
    abbr(registry, 'dcrestart', 'docker container restart')  # Fish line 118
    abbr(registry, 'dcri', 'docker container run -i -t --rm ')  # Fish line 119
    abbr(registry, 'dcrie', 'docker container run -i -t --rm --entrypoint ')  # Fish line 120
    abbr(registry, 'dcrpriv', 'docker container run -i -t --rm --privileged --pid host ubuntu nsenter -t 1 -a')  # Fish line 121
    abbr(registry, 'dcrm', 'docker container rm -f')  # Fish line 122
    abbr(registry, 'dcstart', 'docker container start')  # Fish line 123
    abbr(registry, 'dcstats', 'docker container stats')  # Fish line 124
    abbr(registry, 'dcstop', 'docker container stop')  # Fish line 125
    abbr(registry, 'dct', 'docker container top')  # Fish line 126
    abbr(registry, 'dcunpause', 'docker container unpause')  # Fish line 127
    abbr(registry, 'dcupdate', 'docker container update')  # Fish line 128
    abbr(registry, 'dcwait', 'docker container wait')  # Fish line 129
    abbr(registry, 'di', 'docker image')  # Fish line 131
    abbr(registry, 'dbx', 'docker buildx')  # Fish line 133
    abbr(registry, 'dbxls', 'docker buildx ls')  # Fish line 134
    abbr(registry, 'dbxb', 'docker buildx build')  # Fish line 135
    abbr(registry, 'dbxba', 'docker buildx bake')  # Fish line 136
    abbr(registry, 'dbxc', 'docker buildx create')  # Fish line 137
    abbr(registry, 'dbxrm', 'docker buildx rm')  # Fish line 138
    abbr(registry, 'dbxdu', 'docker buildx du')  # Fish line 139
    abbr(registry, 'dbxi', 'docker buildx inspect')  # Fish line 140
    abbr(registry, 'dbxpr', 'docker buildx prune')  # Fish line 141
    abbr(registry, 'dbxst', 'docker buildx stop')  # Fish line 142
    abbr(registry, 'dbxu', 'docker buildx use')  # Fish line 143
    abbr(registry, 'dbxv', 'docker buildx version')  # Fish line 144
    abbr(registry, 'dbxit', 'docker buildx imagetools')  # Fish line 146
    abbr(registry, 'dib', 'docker image build')  # Fish line 148
    abbr(registry, 'dih', 'docker image history --no-trunc')  # Fish line 150
    abbr(registry, 'dihj', 'docker image history --no-trunc --format "{{json .}}" | jq')  # Fish line 151
    abbr(registry, 'dii', 'docker image inspect')  # Fish line 153
    abbr(registry, 'dils', 'docker image ls')  # Fish line 155
    abbr(registry, 'dilsa', 'docker image ls --all')  # Fish line 156
    abbr(registry, 'dilsj', 'docker image ls --format "{{json .}}" | jq')  # Fish line 157
    abbr(registry, 'dilsaj', 'docker image ls --all --format "{{json .}}" | jq')  # Fish line 158
    abbr(registry, 'dilsdf', "docker image ls --format '{{.Size}}\\t{{.Repository}}:{{.Tag}}' | sort -h")  # Fish line 159
    abbr(registry, 'dipr', 'docker image prune')  # Fish line 161
    abbr(registry, 'dipull', 'docker image pull')  # Fish line 162
    abbr(registry, 'dipush', 'docker image push')  # Fish line 163
    abbr(registry, 'dirm', 'docker image rm')  # Fish line 164
    abbr(registry, 'dit', 'docker image tag')  # Fish line 165
    abbr(registry, 'dm', 'docker manifest')  # Fish line 167
    abbr(registry, 'dmi', 'docker manifest inspect')  # Fish line 168
    abbr(registry, 'dne', 'docker network')  # Fish line 171
    abbr(registry, 'dnec', 'docker network connect')  # Fish line 172
    abbr(registry, 'dned', 'docker network disconnect')  # Fish line 173
    abbr(registry, 'dnei', 'docker network inspect')  # Fish line 174
    abbr(registry, 'dnels', 'docker network ls')  # Fish line 175
    abbr(registry, 'dnepr', 'docker network prune')  # Fish line 176
    abbr(registry, 'dnerm', 'docker network rm')  # Fish line 177
    abbr(registry, 'dx', 'docker context')  # Fish line 179
    abbr(registry, 'dxls', 'docker context ls')  # Fish line 180
    abbr(registry, 'dxu', 'docker context use')  # Fish line 181
    abbr(registry, 'dxud', 'docker context use default')  # Fish line 182
    abbr(registry, 'dxi', 'docker context inspect')  # Fish line 183
    abbr(registry, 'dxc', 'docker context create')  # Fish line 184
    abbr(registry, 'dxrm', 'docker context rm')  # Fish line 185
    abbr(registry, 'dxs', 'docker context show')  # Fish line 186
    abbr(registry, 'dco', 'docker compose')  # Fish line 189
    abbr(registry, 'dcob', 'docker compose build --pull')  # Fish line 190
    abbr(registry, 'dcoc', 'docker compose config')  # Fish line 191
    abbr(registry, 'dcocp', 'docker compose cp')  # Fish line 192
    abbr(registry, 'dcod', 'docker compose down --remove-orphans')  # Fish line 196
    abbr(registry, 'dcodd', 'docker compose down --remove-orphans --dry-run')  # Fish line 197
    abbr(registry, 'dcoda', 'docker compose down --remove-orphans --rmi local --volumes')  # Fish line 198
    abbr(registry, 'dcodad', 'docker compose down --remove-orphans --rmi local --volumes --dry-run')  # Fish line 199
    abbr(registry, 'dcoe', 'docker compose exec')  # Fish line 203
    abbr(registry, 'dcoa', 'docker compose attach')  # Fish line 204
    abbr(registry, 'dcow', 'docker compose watch')  # Fish line 205
    abbr(registry, 'dcoi', 'docker compose images')  # Fish line 206
    abbr(registry, 'dcok', 'docker compose kill')  # Fish line 207
    abbr(registry, 'dcol', 'docker compose logs')  # Fish line 208
    abbr(registry, 'dcolf', 'docker compose logs -f')  # Fish line 209
    abbr(registry, 'dcolt', 'docker compose logs -f --tail=0')  # Fish line 210
    abbr(registry, 'dcops', 'docker compose ps')  # Fish line 211
    abbr(registry, 'dcopsa', 'docker compose ps -a')  # Fish line 212
    abbr(registry, 'dcols', 'docker compose ls')  # Fish line 213
    abbr(registry, 'dcolsa', 'docker compose ls -a')  # Fish line 214
    abbr(registry, 'dcopull', 'docker compose pull')  # Fish line 221
    abbr(registry, 'dcopush', 'docker compose push')  # Fish line 222
    abbr(registry, 'dcorm', 'docker compose rm')  # Fish line 223
    abbr(registry, 'dcor', 'docker compose run --rm')  # Fish line 225
    abbr(registry, 'dcorb', 'docker compose run --rm --build')  # Fish line 226
    abbr(registry, 'dcore', 'docker compose restart')  # Fish line 228
    abbr(registry, 'dcostart', 'docker compose start')  # Fish line 229
    abbr(registry, 'dcostop', 'docker compose stop')  # Fish line 230
    abbr(registry, 'dcot', 'docker compose top')  # Fish line 231
    abbr(registry, 'dcou', 'docker compose up')  # Fish line 232
    abbr(registry, 'dcoub', 'docker compose up --build')  # Fish line 233
    abbr(registry, 'dcouf', 'docker compose up --build --force-recreate --remove-orphans')  # Fish line 234
    abbr(registry, 'dcoud', 'docker compose up --detach')  # Fish line 235
    abbr(registry, 'dcouw', 'docker compose up --watch')  # Fish line 236
    abbr(registry, 'dcov', 'docker compose version')  # Fish line 237
    abbr(registry, 'dd', 'docker debug')  # Fish line 242
    abbr(registry, 'ddc', "docker debug --command '%'", cursor_marker="%")  # Fish line 243
    abbr(registry, 'dde', 'docker debug -c entrypoint')  # Fish line 244
    abbr(registry, 'sk', 'skopeo')  # Fish line 247
    abbr(registry, 'skh', 'skopeo --help')  # Fish line 248
    abbr(registry, 'ski', 'skopeo --override-os linux inspect docker://%', cursor_marker="%")  # Fish line 249
    abbr(registry, 'skim', 'skopeo --override-os linux inspect --raw docker://%', cursor_marker="%")  # Fish line 250
    abbr(registry, 'skic', 'skopeo --override-os linux inspect --config --raw docker://%', cursor_marker="%")  # Fish line 251
    abbr(registry, 'skl', 'skopeo list-tags docker://docker.io/%', cursor_marker="%")  # Fish line 252
    abbr(registry, 'sklm', 'skopeo list-tags docker://mcr.microsoft.com/%', cursor_marker="%")  # Fish line 253
    abbr(registry, 'dh', 'hub-tool')  # Fish line 271
    abbr(registry, 'dhr', 'hub-tool repo ls')  # Fish line 274
    abbr(registry, 'dht', 'hub-tool tag ls --sort=name=desc --platforms --all')  # Fish line 277
    abbr(registry, 'dhtu', 'hub-tool tag ls --sort=updated=desc --platforms --all')  # Fish line 278
    abbr(registry, 'dhtj', 'hub-tool tag ls --format json % | jq', cursor_marker="%")  # Fish line 279
    abbr(registry, 'dhti', 'hub-tool tag inspect')  # Fish line 280
