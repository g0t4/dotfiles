## 1.11.4 commands:
# acl            Interact with Consul's ACLs
# agent          Runs a Consul agent
abbr "ua" "consul agent"
abbr "uad" "consul agent -dev"
# catalog        Interact with the catalog
abbr "uc" "consul catalog"
abbr "ucs" "consul catalog services"
abbr "ucn" "consul catalog nodes"
# config         Interact with Consul's Centralized Configurations
# connect        Interact with Consul Connect
# debug          Records a debugging archive for operators
abbr "ud" "consul debug"
# event          Fire a new event
abbr "uev" "consul event"
# exec           Executes a command on Consul nodes
abbr "uex" "consul exec"
# force-leave    Forces a member of the cluster to enter the "left" state
# info           Provides debugging information for operators.
abbr "ui" "consul info"
# intention      Interact with Connect service intentions
# join           Tell Consul agent to join cluster
# keygen         Generates a new encryption key
# keyring        Manages gossip layer encryption keys
# kv             Interact with the key-value store
abbr "ukv" "consul kv"
abbr "ukvg" "consul kv get"
abbr "ukvgr" "consul kv get -recurse"
abbr "ukvd" "consul kv delete"
abbr "ukvdr" "consul kv delete -recurse"
abbr "ukvp" "consul kv put"
abbr "ukve" "consul kv export"
abbr "ukvi" "consul kv import"
# leave          Gracefully leaves the Consul cluster and shuts down
# lock           Execute a command holding a lock
# login          Login to Consul using an auth method
# logout         Destroy a Consul token created with login
# maint          Controls node or service maintenance mode
# members        Lists the members of a Consul cluster
abbr "umembers" "consul members"
# monitor        Stream logs from a Consul agent
abbr "um" "consul monitor"
abbr "umj" "consul monitor -log-json | jq"
# operator       Provides cluster-level tools for Consul operators
abbr "uo" "consul operator"
abbr "uor" "consul operator raft"
abbr "uorp" "consul operator raft list-peers"
# reload         Triggers the agent to reload configuration files
abbr "ur" "consul reload"
# rtt            Estimates network round trip time between nodes
# services       Interact with services
abbr "us" "consul services"
abbr "usr" "consul services register"
abbr "usd" "consul services deregister"
# snapshot       Saves, restores and inspects snapshots of Consul server state
# tls            Builtin helpers for creating CAs and certificates
# validate       Validate config files/directories
# abbr "uv" "consul validate" # uv command
# version        Prints the Consul version
abbr "uver" "consul version"
# watch          Watch for changes in Consul
abbr "uw" "consul watch"
