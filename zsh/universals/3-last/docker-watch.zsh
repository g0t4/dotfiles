# helpers for my Getting Started with Swarm Mode course (edition2)
# PRN port to fish if useful in a future course

ealias diw="__watch_docker_images"
function __watch_docker_images() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context image ls
}

ealias dcw="__watch_docker_containers"
function __watch_docker_containers() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context container ls
}

ealias dnew="__watch_docker_networks"
function __watch_docker_networks() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context network ls
}

ealias dvw="__watch_docker_volumes"
function __watch_docker_volumes() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context volume ls
}

ealias dstw="__watch_docker_stacks"
function __watch_docker_stacks() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context stack ls
}

ealias dsvw="__watch_docker_services"
function __watch_docker_services() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context services ls
}

ealias dnow="__watch_docker_nodes"
function __watch_docker_nodes() {
    local _context="${1:-default}"
    watch --no-title -n 0.5 -d docker -c $_context node ls
}
