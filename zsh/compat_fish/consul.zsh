## 1.11.4 commands:
# acl            Interact with Consul's ACLs
# agent          Runs a Consul agent
eabbr "ua" "consul agent"
eabbr "uad" "consul agent -dev"
# catalog        Interact with the catalog
eabbr "uc" "consul catalog"
eabbr "ucs" "consul catalog services"
eabbr "ucn" "consul catalog nodes"
# config         Interact with Consul's Centralized Configurations
# connect        Interact with Consul Connect
# debug          Records a debugging archive for operators
eabbr "ud" "consul debug"
# event          Fire a new event
eabbr "uev" "consul event"
# exec           Executes a command on Consul nodes
eabbr "uex" "consul exec"
# force-leave    Forces a member of the cluster to enter the "left" state
# info           Provides debugging information for operators.
eabbr "ui" "consul info"
# intention      Interact with Connect service intentions
# join           Tell Consul agent to join cluster
# keygen         Generates a new encryption key
# keyring        Manages gossip layer encryption keys
# kv             Interact with the key-value store
eabbr "ukv" "consul kv"
eabbr "ukvg" "consul kv get"
eabbr "ukvgr" "consul kv get -recurse"
eabbr "ukvd" "consul kv delete"
eabbr "ukvdr" "consul kv delete -recurse"
eabbr "ukvp" "consul kv put"
eabbr "ukve" "consul kv export"
eabbr "ukvi" "consul kv import"
# leave          Gracefully leaves the Consul cluster and shuts down
# lock           Execute a command holding a lock
# login          Login to Consul using an auth method
# logout         Destroy a Consul token created with login
# maint          Controls node or service maintenance mode
# members        Lists the members of a Consul cluster
eabbr "umembers" "consul members"
# monitor        Stream logs from a Consul agent
eabbr "um" "consul monitor"
eabbr "umj" "consul monitor -log-json | jq"
# operator       Provides cluster-level tools for Consul operators
eabbr "uo" "consul operator"
eabbr "uor" "consul operator raft"
eabbr "uorp" "consul operator raft list-peers"
# reload         Triggers the agent to reload configuration files
eabbr "ur" "consul reload"
# rtt            Estimates network round trip time between nodes
# services       Interact with services
eabbr "us" "consul services"
eabbr "usr" "consul services register"
eabbr "usd" "consul services deregister"
# snapshot       Saves, restores and inspects snapshots of Consul server state
# tls            Builtin helpers for creating CAs and certificates
# validate       Validate config files/directories
eabbr "uv" "consul validate"
# version        Prints the Consul version
eabbr "uver" "consul version"
# watch          Watch for changes in Consul
eabbr "uw" "consul watch"
