### *************** TELL WIN TERMINAL ABOUT PATH
# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory#wsl
keep_current_path() {
  if [[ -z "$WT_SESSION" ]]; then
    return
  fi
  printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
}
precmd_functions+=(keep_current_path)
