# pass an option (key) filter => 0 or more matching option names and details of each!
ealias aclsn="_ansible-config_options_name_contains"
_ansible-config_options_name_contains() {
  filter=$@
  \ansible-config list | yq "with_entries(select(.key | test(\"(?i).*${filter}.*\")))"
}
ealias aclsd="_ansible-config_option_details_contains"
_ansible-config_option_details_contains() {
  key=$1
  \ansible-config list | yq "with_entries(select(.. | has(\"$key\")))"
}

