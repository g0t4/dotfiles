## 1.11.4 commands:
# acl            Interact with Consul's ACLs
# agent          Runs a Consul agent
ealias "ua"="consul agent"
ealias "uad"="consul agent -dev"
# catalog        Interact with the catalog
ealias "uc"="consul catalog"
ealias "ucs"="consul catalog services"
ealias "ucn"="consul catalog nodes"
# config         Interact with Consul's Centralized Configurations
# connect        Interact with Consul Connect
# debug          Records a debugging archive for operators
ealias "ud"="consul debug"
# event          Fire a new event
ealias "uev"="consul event"
# exec           Executes a command on Consul nodes
ealias "uex"="consul exec"
# force-leave    Forces a member of the cluster to enter the "left" state
# info           Provides debugging information for operators.
ealias "ui"="consul info"
# intention      Interact with Connect service intentions
# join           Tell Consul agent to join cluster
# keygen         Generates a new encryption key
# keyring        Manages gossip layer encryption keys
# kv             Interact with the key-value store
ealias "ukv"="consul kv"
ealias "ukvg"="consul kv get"
ealias "ukvgr"="consul kv get -recurse"
ealias "ukvd"="consul kv delete"
ealias "ukvdr"="consul kv delete -recurse"
ealias "ukvp"="consul kv put"
ealias "ukve"="consul kv export"
ealias "ukvi"="consul kv import"
# leave          Gracefully leaves the Consul cluster and shuts down
# lock           Execute a command holding a lock
# login          Login to Consul using an auth method
# logout         Destroy a Consul token created with login
# maint          Controls node or service maintenance mode
# members        Lists the members of a Consul cluster
ealias "umembers"="consul members"
# monitor        Stream logs from a Consul agent
ealias "um"="consul monitor"
ealias "umj"="consul monitor -log-json | jq"
# operator       Provides cluster-level tools for Consul operators
ealias "uo"="consul operator"
ealias "uor"="consul operator raft"
ealias "uorp"="consul operator raft list-peers"
# reload         Triggers the agent to reload configuration files
ealias "ur"="consul reload"
# rtt            Estimates network round trip time between nodes
# services       Interact with services
ealias "us"="consul services"
ealias "usr"="consul services register"
ealias "usd"="consul services deregister"
# snapshot       Saves, restores and inspects snapshots of Consul server state
# tls            Builtin helpers for creating CAs and certificates
# validate       Validate config files/directories
ealias "uv"="consul validate"
# version        Prints the Consul version
ealias "uver"="consul version"
# watch          Watch for changes in Consul
ealias "uw"="consul watch"
