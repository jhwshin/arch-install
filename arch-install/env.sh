INTERACTIVE_MODE=true

# disk partition
EFI_PARTITION="/dev/sda1"
ROOT_PARTITION=""                   # e.g /dev/sda2
SWAPFILE_SIZE="9G"                  # RAM_SIZE + 1G

MIRROR_REGIONS="AU,NZ"              # $ reflector --list-countries
LOCALE_GEN=(
    "en_AU.UTF-8 UTF-8"
    "en_US.UTF-8 UTF-8"
)
LOCALE_SYSTEM="en_AU.UTF-8"         # $ less /etc/locale.gen
TIMEZONE_REGION="Australia"         # $ ls /usr/share/zoneinfo/<REGION>/<CITY>
TIMEZONE_CITY="Sydney"

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