# install fisher
# https://github.com/jorgebucaran/fisher
# PRN version fish_plugins (which fisher mentions as a way to share plugins, but it shows that as if fisher is already installed locally so lets do that w/o fish_plugins)
# if fisher function not avail then install fisher
if not functions -q fisher
  echo "installing fisher"
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
end

# install z
if not functions -q __z
  echo "installing z"
  fisher install jethrokuan/z
end

# if not command -q bass
#   echo "installing bass"
#   fisher install edc/bass
# end