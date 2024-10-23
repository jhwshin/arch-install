INTERACTIVE_MODE=true

# disk partition
EFI_PARTITION="/dev/sda1"
ROOT_PARTITION=""                   # e.g /dev/sda2
SWAPFILE_SIZE="9G"                  # RAM_SIZE + 1G

MIRROR_REGIONS="AU,NZ"              # $ reflector --list-countries

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