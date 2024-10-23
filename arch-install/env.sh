INTERACTIVE_MODE=true

# disk partition
EFI_PARTITION="/dev/sda1"
ROOT_PARTITION=""                   # e.g /dev/sda2
SWAPFILE_SIZE="9G"                  # RAM_SIZE + 1G

USERNAME="USER"
HOSTNAME="ARCH"

MIRROR_REGIONS="AU,NZ"              # $ reflector --list-countries
LOCALE_GEN=(
    "en_AU.UTF-8 UTF-8"
    "en_US.UTF-8 UTF-8"
)
LOCALE_SYSTEM="en_AU.UTF-8"         # $ less /etc/locale.gen
TIMEZONE_REGION="Australia"         # $ ls /usr/share/zoneinfo/<REGION>/<CITY>
TIMEZONE_CITY="Sydney"

CPU=(
    "intel"
)
GPU=(
    "intel"
    # "nvidia"
)

BOOTLOADER="refind"

# ------------------------------------------------
#   Packages
# ------------------------------------------------

BASE_PACKAGES=(
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
    xdg-utils
    xdg-user-dirs
    zsh
    btrfs-progs
    ntfs-3g
    iwd
)

XORG_PACKAGES=(
    xorg
    xorg-apps
    xorg-xinit
)

GPU_INTEL_PACKAGES=(
    xf86-video-intel
    mesa
    lib32-mesa
    vulkan-intel
    lib32-vulkan-intel
    intel-gpu-tools
)

GPU_NVIDIA_PACKAGES=(
    nvidia-dkms
    nvidia-utils
    lib32-nvidia-utils
    nvidia-settings
    nvtop
)

DESKTOP_ENVIRONMENTS=(
    i3
    dmenu
    xfce4
    xfce4-goodies
    gnome
    gnome-extra
)

# ------------------------------------------------
#   CONFIGS
# ------------------------------------------------

HOSTS_CONF="127.0.0.1                                   localhost
::1                                         localhost
127.0.1.1       ${HOSTNAME}.localdomain         ${HOSTNAME}"

INTEL_XORG_CONF='# prevent screen tearing for intel
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
EndSection'