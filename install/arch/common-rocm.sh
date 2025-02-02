# AMD GPU support
sudo pacman --needed --noconfirm -S \
    rocm-hip-sdk rocminfo rocm-hip-runtime hipblas

# confirm device:
rocminfo | grep gfx | head -1 | awk '{print $2}'
