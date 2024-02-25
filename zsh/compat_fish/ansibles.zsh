abbr ap "ansible-playbook"
  abbr apv "ansible-playbook -v"
  abbr apvv "ansible-playbook -vv"
  abbr apvvv "ansible-playbook -vvv"
abbr aps "ansible-playbook --syntax-check"
  abbr apc "ansible-playbook --check"
  abbr apcd "ansible-playbook --check --diff"

abbr aplsh "ansible-playbook --list-hosts"
abbr aplst "ansible-playbook --list-tags"
  abbr aplsk "ansible-playbook --list-tasks"

abbr al "ansible-lint"

abbr ad "ansible-doc"
# abbr admdd "ansible-doc --metadata-dump COLLECTION | jq"
#    i.e. ansible-doc --metadata-dump ansible.builtin | jq ".all | keys"  #  all builtin plugin types
abbr adls "ansible-doc --list"
abbr adlsf "ansible-doc --list_files"
  abbr ads "ansible-doc --snippet" # ads homebrew

# "ag" reserved for silver searcher
abbr a-gc "ansible-galaxy collection"
abbr a-gcls "ansible-galaxy collection list"
abbr a-gci "ansible-galaxy collection install"
abbr a-gcir "ansible-galaxy collection install -r requirements.yml"
abbr a-gcd "ansible-galaxy collection download"
# ? info, search, uninstall* (especially) sub commands

abbr ac "ansible-config"
  abbr acl "ansible-config list"
    abbr acls "ansible-config list"
  abbr acv "ansible-config view"
  abbr acd "ansible-config dump"
    abbr acdo "ansible-config dump --only-changed"
  abbr aci "ansible-config init"
    abbr acif "ansible-config init --format" # ini,env,vars
    abbr acifi "ansible-config init --format ini"
    abbr acife "ansible-config init --format env"
    abbr acifv "ansible-config init --format vars"

abbr av "ansible-vault"

abbr ai "ansible-inventory"
  abbr ails "ansible-inventory --list --yaml"
    abbr ailsv "ansible-inventory --list --vars"
    abbr ailst "ansible-inventory --list --toml"
      abbr ailstv "ansible-inventory --list --toml --vars"
  abbr aig "ansible-inventory --graph"
  abbr aih "ansible-inventory --host "

abbr apull "ansible-pull"
