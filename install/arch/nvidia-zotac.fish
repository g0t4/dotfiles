# FYI https://wiki.archlinux.org/title/NVIDIA

# 50 series uses open source driver
sudo pacman -Syu --noconfirm nvidia-open nvidia-utils
# not using nvidia-dkms (yet?)
# not using nvidia # legacy, proprietary driver (for older cards)

# general pkgs
sudo pacman -Syu --noconfirm lshw hwinfo
sudo pacman -Syu --noconfirm mesa-utils # opengl info

# nvcc:
sudo pacman -Syu --noconfirm cuda cudnn
# added to path too /opt/cuda/bin (see paths.fish)





# blacklist nouveau
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
sudo mkinitcpio -P
sudo reboot


# confirms
nvidia-smi # double check works
lspci -k -d ::03xx
lspci -tv
# for ollama
ollama server # see if detects GPU (best test, can you use it?)

hwinfo --gfxcard
