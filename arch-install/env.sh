INTERACTIVE_MODE=true

# disk partition
EFI_PARTITION="/dev/sda1"
ROOT_PARTITION=""                   # e.g /dev/sda2
SWAPFILE_SIZE="9G"                  # RAM_SIZE + 1G

USERNAME="USER"
HOSTNAME="ARCH"

GPU=(
    "intel"
    # "nvidia"
)

MODULES=(
    i915                    # intel keyboard
    usbhid                  # usb3 hub via luks
    xhci_hcd                # usb3 hub via luks
    # nvidia
    # nvidia_modeset
    # nvidia_uvm
    # nvidia_drm
)

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

BOOTLOADER="refind"

SYSTEMD_STARTUPS=(
    NetworkManager
    bluetooth
    reflector
    gdm
)

HOOKS=(
    base
    systemd
    # autodetect
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

COW_ROOT="@"

SWAP_NAME="@swap"
SWAP_MNT="/.swapvol"

COW_NAME=(
    @home
    @snapshots
)
COW_MNT=(
    /home
    /.snapshots
)

NOCOW_NAME=(
    @var_log
    @var_cache
    @var_tmp
    @docker
    @libvirt
)
NOCOW_MNT=(
    /var/log
    /var/cache
    /var/tmp
    /var/lib/docker
    /var/lib/libvirt/images
)

COW_OPTS="noatime,nodiratime,compress=zstd:3"
NOCOW_OPTS="noatime,nodiratime,compress=no"

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
    # lvm2
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

BASIC_PACKAGES=(
    alsa-utils                  # audio
    pavucontrol                 # audio
    networkmanager              # internet
    network-manager-applet      # internet
    bluez                       # bluetooth
    bluez-utils                 # bluetooth
    blueman                     # bluetooth
    openssh
    reflector                   # mirror
    gdm
)

AUR_PACKAGES=(
    firefox                     # web browser
    kitty                       # terminal
    mpv                         # media player
)

# ------------------------------------------------
#   CONFIGS
# ------------------------------------------------

HOSTS_CONF="
127.0.0.1                                   localhost
::1                                         localhost"

INTEL_XORG_CONF='# prevent screen tearing for intel
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
EndSection'

REFLECTOR_CONF="--country '${MIRROR_REGIONS}'
--latest 10
--number 10
--sort rate
--save /etc/pacman.d/mirrorlist"