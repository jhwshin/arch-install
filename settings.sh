#!/usr/bin/env bash

# verify each step
VERIFY=true

# ----------------------------------------------------------
# IMPORTANT (MODIFY)
# ----------------------------------------------------------

BOOT_PARTITION=""
ROOT_PARTITION=""
SWAPFILE_SIZE="97G"
USERNAME=""
HOSTNAME=""

# ----------------------------------------------------------
# DRIVERS (MODIFY)
# ----------------------------------------------------------

BOOTLOADER="refind" # grub, refind
CPU="amd" # amd, intel
GPU=(
    "nvidia"
    # amd
)
DISPLAY_SERVERS=(
    "x11"
    #"wayland"
)

# ----------------------------------------------------------
# BOOT OPTS (MODIFY)
# ----------------------------------------------------------

# fbcon=map:<FBDRM_NUM>
# fbcon=rotate:<1 or 3> (portrait monitor)
KERNEL_PARAMS="" 

INITRAMFS_MODULES=(
    amdgpu              # amd igpu
    # i915              # intel igpu
    nvidia              # nvidia
    nvidia_modeset      # nvidia
    nvidia_uvm          # nvidia
    nvidia_drm          # nvidia
    usbhid              # usb
    xhci_hcd            # ?
)
INITRAMFS_HOOKS=(
    base
    systemd
    autodetect
    microcode
    modconf
    kms
    keyboard
    sd-vconsole
    block
    sd-encrypt
    # lvm2
    filesystems
    resume
    fsck
)

# ----------------------------------------------------------
# PRECHROOT OPTS
# ----------------------------------------------------------

BTRFS_SU_COW_OPTS="noatime,compress=zstd:3,space_cache=v2,ssd,discard=async"
BTRFS_SU_NOCOW_OPTS="noatime,compress=no,space_cache=v2,ssd,discard=async"

# ----------------------------------------------------------
# CHROOT OPTS
# ----------------------------------------------------------

MIRROR_REGIONS="AU,NZ" # reflector --list-countries
LOCALE_GEN=(
    "en_AU.UTF-8 UTF-8"
    "en_US.UTF-8 UTF-8"
)
LOCALE_SYSTEM="en_AU.UTF-8" # /etc/locale.gen
TIMEZONE_REGION="Australia" # /usr/share/zoneinfo/<REGION>/<CITY>
TIMEZONE_CITY="Sydney"

SYSTEMD_SERVICES=(
    NetworkManager
    bluetooth
    reflector
    # sshd
)

# ----------------------------------------------------------
# PACKAGE LISTS
# ----------------------------------------------------------

ARCH_BASE_PKGS=(
    base
    base-devel
    linux
    linux-headers
    linux-lts
    linux-lts-headers
    linux-zen
    linux-zen-headers
    linux-api-headers
    linux-firmware
    git
    nano
    nano-syntax-highlighting
    rsync
    xdg-utils
    xdg-user-dirs
    btrfs-progs
    ntfs-3g
    iwd
)

BOOTLOADER_GRUB_PKGS=(
    grub
)

BOOTLOADER_REFIND_PKGS=(
    refind
)

CPU_INTEL_PKGS=(
    intel-ucode
)

CPU_AMD_PKGS=(
    amd-ucode
)

GPU_INTEL_PKGS=(
    mesa
    lib32-mesa
    vulkan-intel
    lib32-vulkan-intel
    xf86-video-intel
    intel-gpu-tools
)

GPU_AMD_PKGS=(
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    xf86-video-amdgpu
    amdgpu_top
)

GPU_NVIDIA_PKGS=(
    nvidia-dkms
    nvidia-utils
    lib32-nvidia-utils
    nvidia-settings
    nvtop
)

DISPLAY_SERVER_X11_PKGS=(
    xorg
    xorg-apps
    xorg-xinit
)

DESKTOP_ENVIRONMENT_PKGS=(
    i3
    dmenu
    xfce4
    xfce4-goodies
    gnome
    gnome-extra
)

BASIC_PKGS=(
    alsa-utils
    pavucontrol
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    openssh
    reflector
    kitty
    firefox
    mpv
    zsh
)

AUR_PKGS=(

)
