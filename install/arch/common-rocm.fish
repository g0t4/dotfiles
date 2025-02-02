# AMD GPU support
sudo pacman --needed --noconfirm -S \
    rocm-hip-sdk rocminfo rocm-hip-runtime hipblas

# add hipconfig to path
set PATH /opt/rocm/bin $PATH

# confirm device:
rocminfo | grep gfx | head -1 | awk '{print $2}'
