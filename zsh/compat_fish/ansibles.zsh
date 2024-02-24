eabbr ap "ansible-playbook"
  eabbr apv "ansible-playbook -v"
  eabbr apvv "ansible-playbook -vv"
  eabbr apvvv "ansible-playbook -vvv"
eabbr aps "ansible-playbook --syntax-check"
  eabbr apc "ansible-playbook --check"
  eabbr apcd "ansible-playbook --check --diff"

eabbr aplsh "ansible-playbook --list-hosts"
eabbr aplst "ansible-playbook --list-tags"
  eabbr aplsk "ansible-playbook --list-tasks"

eabbr al "ansible-lint"

eabbr ad "ansible-doc"
# eabbr admdd "ansible-doc --metadata-dump COLLECTION | jq"
#    i.e. ansible-doc --metadata-dump ansible.builtin | jq ".all | keys"  #  all builtin plugin types
eabbr adls "ansible-doc --list"
eabbr adlsf "ansible-doc --list_files"
  eabbr ads "ansible-doc --snippet" # ads homebrew

# "ag" reserved for silver searcher
eabbr a-gc "ansible-galaxy collection"
eabbr a-gcls "ansible-galaxy collection list"
eabbr a-gci "ansible-galaxy collection install"
eabbr a-gcir "ansible-galaxy collection install -r requirements.yml"
eabbr a-gcd "ansible-galaxy collection download"
# ? info, search, uninstall* (especially) sub commands

eabbr ac "ansible-config"
  eabbr acl "ansible-config list"
    eabbr acls "ansible-config list"
  eabbr acv "ansible-config view"
  eabbr acd "ansible-config dump"
    eabbr acdo "ansible-config dump --only-changed"
  eabbr aci "ansible-config init"
    eabbr acif "ansible-config init --format" # ini,env,vars
    eabbr acifi "ansible-config init --format ini"
    eabbr acife "ansible-config init --format env"
    eabbr acifv "ansible-config init --format vars"

eabbr av "ansible-vault"

eabbr ai "ansible-inventory"
  eabbr ails "ansible-inventory --list --yaml"
    eabbr ailsv "ansible-inventory --list --vars"
    eabbr ailst "ansible-inventory --list --toml"
      eabbr ailstv "ansible-inventory --list --toml --vars"
  eabbr aig "ansible-inventory --graph"
  eabbr aih "ansible-inventory --host "

eabbr apull "ansible-pull"
