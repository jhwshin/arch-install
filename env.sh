# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#   START CONFIG
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

INTERACTIVE_MODE=true

# partitioning
EFI_PARTITION="/dev/sda"
ROOT_PARTITION=""
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

BOOTLOADER="refind"

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

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#   END CONFIG
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

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

VCONSOLE_CONF="KEYMAP=us
FONT=Lat2-Terminus16"

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

REFIND_BOOT_ENTRY='
# Global Settings
timeout 10                          #   [-1, 0, 0+] (skip, no timeout, x seconds)
log_level 0                         #   [0-4]
#enable_touch
#enable_mouse
#dont_scan_volumes "<LABEL>"        #   Prevent duplicate non-custom Linux entries using <LABEL> use `e2label` to label partition
                                    #   or for LUKS `cryptsetup config /dev/<sdXY> --label <LABEL>``
default_selection +                 #   Microsoft, Arch, + (most recently boot)
resolution max

# UI Settings
# hideui banner, label, singleuser, arrows, hints, editor, badges
hideui singleuser, arrows, label
# shell, memtest, mok_tool, hidden_tags, shutdown, reboot, firmware
showtools mok_tool, hidden_tags, reboot, shutdown, firmware

menuentry "Arch Linux" {
    icon            /EFI/refind/themes/refind-dreary/icons/os_arch.png
    volume          "CRYPTROOT"
    loader          /vmlinuz-linux
    initrd          /initramfs-linux.img
    options         "rd.luks.name=${CRYPT_UUID}=crypt root=/dev/mapper/crypt rootflags=subvol=@ resume=/dev/mapper/crypt resume_offset=${RESUME_OFFSET} rw ${NVIDIA_KERNEL_PARAMS}"


    submenuentry "Linux fallback initramfs" {
        loader  /vmlinuz-linux
        initrd  /initramfs-linux-fallback.img
    }
    submenuentry "Boot to terminal" {
        add_options "systemd.unit=multi-user.target"
    }
    submenuentry "Linux-lts" {
        loader  /vmlinuz-linux-lts
        initrd  /initramfs-linux-lts.img
    }
    submenuentry "Linux-lts fallback" {
        loader  /vmlinuz-linux-lts
        initrd  /initramfs-linux-lts-fallback.img
    }
    submenuentry "Linux-zen" {
        loader  /vmlinuz-linux-zen
        initrd  /initramfs-linux-zen.img
    }
    submenuentry "Linux-zen fallback" {
        loader  /vmlinuz-linux-zen
        initrd  /initramfs-linux-zen-fallback.img
    }
}
'

KERNEL_PARAMS=""
NVIDIA_KERNEL_PARAMS="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"

NETWORK_MANAGER_CONF="[device]
wifi.backend=iwd"

REFLECTOR_CONF="--country \"${MIRROR_REGIONS}\"
--latest 10
--number 10
--sort rate
--save /etc/pacman.d/mirrorlist"

# ------------------------------------------------
#   PACMAN HOOKS
# ------------------------------------------------

NVIDIA_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=nvidia-lts
Target=nvidia-dkms
Target=nvidia-utils
Target=lib32-nvidia-utils
Target=linux
Target=linux-lts
Target=linux-hardened
Target=linux-zen

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'"

# secure boot hooks
MOKS_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=linux
Target=linux-lts
Target=linux-hardened
Target=linux-zen
Target=linux-surface

[Action]
Description=Signing kernel with Machine Owner Key for Secure Boot
When=PostTransaction
Exec=/usr/bin/find /boot/ -maxdepth 1 -name 'vmlinuz-*' -exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null | /usr/bin/grep -q \"signature certificates\"; then /usr/bin/sbsign --key /etc/refind.d/keys/refind_local.key --cert /etc/refind.d/keys/refind_local.crt --output {} {}; fi';
Depends=sbsigntools
Depends=findutils
Depends=grep"

REFIND_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=refind

[Action]
Description=Updating rEFInd on ESP
When=PostTransaction
Exec=/usr/bin/refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys"

ZSH_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Path
Target=usr/bin/*

[Action]
Depends=zsh
When=PostTransaction
Exec=/usr/bin/install -Dm644 /dev/null /var/cache/zsh/pacman"