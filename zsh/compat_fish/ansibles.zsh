ealias ap="ansible-playbook"
  ealias apv="ansible-playbook -v"
  ealias apvv="ansible-playbook -vv"
  ealias apvvv="ansible-playbook -vvv"
ealias aps="ansible-playbook --syntax-check"
  ealias apc="ansible-playbook --check"
  ealias apcd="ansible-playbook --check --diff"

ealias aplsh="ansible-playbook --list-hosts"
ealias aplst="ansible-playbook --list-tags"
  ealias aplsk="ansible-playbook --list-tasks"

ealias al="ansible-lint"

ealias ad="ansible-doc"
# ealias admdd="ansible-doc --metadata-dump COLLECTION | jq"
#    i.e. ansible-doc --metadata-dump ansible.builtin | jq ".all | keys"  #  all builtin plugin types
ealias adls="ansible-doc --list"
ealias adlsf="ansible-doc --list_files"
  ealias ads="ansible-doc --snippet" # ads homebrew

# "ag" reserved for silver searcher
ealias a-gc="ansible-galaxy collection"
ealias a-gcls="ansible-galaxy collection list"
ealias a-gci="ansible-galaxy collection install"
ealias a-gcir="ansible-galaxy collection install -r requirements.yml"
ealias a-gcd="ansible-galaxy collection download"
# ? info, search, uninstall* (especially) sub commands

ealias ac="ansible-config"
  ealias acl="ansible-config list"
    ealias acls="ansible-config list"
  ealias acv="ansible-config view"
  ealias acd="ansible-config dump"
    ealias acdo="ansible-config dump --only-changed"
  ealias aci="ansible-config init"
    ealias acif="ansible-config init --format" # ini,env,vars
    ealias acifi="ansible-config init --format ini"
    ealias acife="ansible-config init --format env"
    ealias acifv="ansible-config init --format vars"

ealias av="ansible-vault"

ealias ai="ansible-inventory"
  ealias ails="ansible-inventory --list --yaml"
    ealias ailsv="ansible-inventory --list --vars"
    ealias ailst="ansible-inventory --list --toml"
      ealias ailstv="ansible-inventory --list --toml --vars"
  ealias aig="ansible-inventory --graph"
  ealias aih="ansible-inventory --host "

ealias apull="ansible-pull"
