# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#   START CONFIG
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

INTERACTIVE_MODE=true

# partitioning
EFI_PARTITION="/dev/sda"
ROOT_PARTITION=""                   # e.g /dev/sda2
SWAPFILE_SIZE="9G"                  # 0 = none (recommended = RAM size + 1GB)

# locale and timezones
MIRROR_REGIONS="AU,NZ"              # $ reflector --list-countries
LOCALE_GEN=(
    "en_AU.UTF-8 UTF-8"
    "en_US.UTF-8 UTF-8"
)

LOCALE_SYSTEM="en_AU.UTF-8"         # $ less /etc/locale.gen
TIMEZONE_REGION="Australia"         # $ ls /usr/share/zoneinfo/<REGION>/<CITY>
TIMEZONE_CITY="Sydney"

USERNAME="USER"
HOSTNAME="ARCH"

# microcode and drivers
CPU=(
    "intel"
)
GPU=(
    "intel"
    # "nvidia"
)

BOOTLOADER="refind"         # refind or grub

# initramfs
MODULES=(
    i915                    # intel keyboard
    usbhid                  # usb3 hub via luks
    xhci_hcd                # usb3 hub via luks
    # nvidia
    # nvidia_modeset
    # nvidia_uvm
    # nvidia_drm
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

SYSTEMD_STARTUPS=(
    NetworkManager
    bluetooth
    reflector
)

# ------------------------------------------------
#   Packages
# ------------------------------------------------

BASE_PACKAGES=(
    base
    base-devel
    linux-api-headers
    linux-firmware
    linux
    linux-headers
    linux-lts
    linux-lts-headers
    linux-zen
    linux-zen-headers
    git
    nano
    nano-syntax-highlighting
    xdg-utils
    xdg-user-dirs
    zsh
    btrfs-progs
    iwd
    ntfs-3g
)
DESKTOP_ENVIRONMENTS=(
    i3
    dmenu
    xfce4
    xfce4-goodies
    gnome
    gnome-extra
)
ADDITIONAL_PACKAGES=(
    alsa-utils                  # audio
    pavucontrol                 # audio
    networkmanager              # internet
    network-manager-applet      # internet
    bluez                       # bluetooth
    bluez-utils                 # bluetooth
    blueman                     # bluetooth
    openssh
    reflector                   # mirror
)
AUR_PACKAGES=(
    firefox                     # web browser
    kitty                       # terminal
    mpv                         # media player
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

# ------------------------------------------------
#   CONFIGS
# ------------------------------------------------

HOSTS_CONF="127.0.0.1                                   localhost
::1                                         localhost
127.0.1.1       ${HOSTNAME}.localdomain     ${HOSTNAME}"

INTEL_XORG_CONF='# prevent screen tearing for intel
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
EndSection'

                # add to kernel parameter to preserve memory after suspend
#                 cat > /etc/modprobe.d/nvidia-power-management.conf << EOF
# options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
# EOF

KERNEL_PARAMS=""
NVIDIA_KERNEL_PARAMS="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"

NETWORK_MANAGER_CONF="[device]
wifi.backend=iwd"

REFLECTOR_CONF="--country '${MIRROR_REGIONS}'
--latest 10
--number 10
--sort rate
--save /etc/pacman.d/mirrorlist"

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#   END CONFIG
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
