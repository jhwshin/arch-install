#! /usr/bin/env bash

# ================================================
#   Arch Install Script
#       by jhwshin
# ================================================

# print executed commands (debugging)
# set -x

# interactive mode to verify each steps
DEBUG_MODE=true

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#   START CONFIG
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# mount partitions
EFI_PARTITION="/dev/sda1"
ROOT_PARTITION=""

# mirrors
# $ reflector --list-countries
MIRROR_REGIONS="AU,NZ"

# locale
# $ less /etc/locale.gen
LOCALE_GEN=(
    "en_AU.UTF-8 UTF-8"
    "en_US.UTF-8 UTF-8"
)
LOCALE_SYSTEM="en_AU.UTF-8"

# timezone
# $ ls /usr/share/zoneinfo/<REGION>/<CITY>
TIMEZONE_REGION="Australia"
TIMEZONE_CITY="Sydney"

# username + hostname
USERNAME="USER"
HOSTNAME="ARCH"

# swap (ram size + 1GB)
# SWAPFILE_SIZE="0"
SWAPFILE_SIZE="9G"

# drivers
CPU=(
    "intel"
)

GPU=(
    "intel"
    # "nvidia"
)

# bootloader
BOOTLOADER="refind"

# mkinitcpio.conf
# i915 = intelkeyboard
# usbhid + xhci_hcd = usb3 hub via luks
# nvidia = nvidia eary loading
MODULES=(
    i915
    usbhid
    xhci_hcd
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

# systemd
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
)

DE=(
    i3
    dmenu
    xfce4
    xfce4-goodies
    gnome
    gnome-extra
)

ADDITIONAL_PACKAGES=(
    alsa-utils
    pavucontrol
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    openssh
    reflector
)

AUR_PACKAGES=(
    firefox
    kitty
    mpv
)

XORG_PACKAGES=(
    xorg
    xorg-apps
)

GPU_INTEL_PACKAGES=(
    xf86-video-intel
    mesa
    lib32-mesa
    vulkan-intel
    lib32-vulkan-intel
)

GPU_NVIDIA_PACKAGES=(
    nvidia-dkms
    nvidia-utils
    lib32-nvidia-utils
    nvidia-settings
)

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#   END CONFIG
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

SCRIPT_NAME=$(basename "${0}")
FULL_PATH=$(realpath "${0}")

# ------------------------------------------------
#   Pre-chroot Functions
# ------------------------------------------------

setup_luks() {
    echo ">> Setting up LUKS..."

    # format luks with optimized configs for ssd encryption
    cryptsetup luksFormat \
        --perf-no_read_workqueue \
        --perf-no_write_workqueue \
        --type luks2 \
        --cipher aex-xts-plain64 \
        --key-size 512 \
        --iter-time 2000 \
        --pbkdf argon2id \
        --hash sha3-512 \
        --label "CRYPT_ROOT" \
        --verbose \
        "${ROOT_PARTITION}"

    # open container with persistent options to save parameters
    cryptsetup \
        --allow-discard \
        --perf-no_read_workqueue \
        --perf-no_write_workqueue \
        --persistent \
        --verbose \
        open "${ROOT_PARTITION}" crypt

    # verify LUKS container
    ${DEBUG_MODE} && \
        cryptsetup luksDump "${ROOT_PARTITION}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

setup_btrfs() {
    echo ">> Setting up BTRFS..."

    # format btrfs
    mkfs.btrfs -L ROOT /dev/mapper/crypt

    # mount ROOT container
    mount /dev/mapper/crypt /mnt

    # create btrfs subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@srv

    btrfs subvolume create /mnt/@snapshots

    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@cache

    btrfs subvolume create /mnt/@libvirt
    btrfs subvolume create /mnt/@swap

    ${DEBUG_MODE} && \
        btrfs subvolume list /mnt && \
        printf "\nPress Enter to continue...\n\n"; read; clear

    umount /mnt

    echo ">> Mounting partitions..."

    mount -o noatime,nodiratime,compress=zstd:1,subvol=@            /dev/mapper/crypt   /mnt
    
    mkdir -p /mnt/{boot,home,srv,.snapshots,tmp,.swapvol,btrfs}
    mkdir -p /mnt/var/{log,cache,lib/libvirt/images}

    mount -o noatime,nodiratime,compress=zstd:1,subvol=@home        /dev/mapper/crypt   /mnt/home
    mount -o noatime,nodiratime,compress=zstd:1,subvol=@srv         /dev/mapper/crypt   /mnt/srv
    mount -o noatime,nodiratime,compress=zstd:1,subvol=@snapshots   /dev/mapper/crypt   /mnt/.snapshots
    mount -o noatime,nodiratime,compress=zstd:1,subvol=@log         /dev/mapper/crypt   /mnt/var/log
    mount -o noatime,nodiratime,compress=zstd:1,subvol=@cache       /dev/mapper/crypt   /mnt/var/cache
    
    mount -o noatime,nodiratime,compress=zstd:1,subvolid=5          /dev/mapper/crypt   /mnt/btrfs

    # this may not work (nodatacow and datacow can't be on the same file system)
    # try instead set '$ chattr +C <PATH>'
    mount -o compress=no,subvol=@libvirt                            /dev/mapper/crypt   /mnt/var/lib/libvirt/images
    mount -o compress=no,subvol=@swap                               /dev/mapper/crypt   /mnt/.swapvol

    # disable CoW for certain folders
    chattr +C /mnt/var/lib/libvirt/images
    chattr +C /mnt/.swapvol
    chattr +C /mnt/tmp

    # mount EFI partition
    mount "${EFI_PARTITION}" /mnt/boot

    # verify mounts
    ${DEBUG_MODE} && \
        findmnt -a | grep /mnt && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

setup_swapfile() {
    echo ">> Setting up SWAP file..."

    btrfs filesystem mkswapfile --size "${SWAPFILE_SIZE}" /mnt/.swapvol/swapfile
    swapon /mnt/.swapvol/swapfile

    # verify swap
    ${DEBUG_MODE} && \
        swapon -s && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

update_mirrorlist() {
    echo ">> Updating mirrors..."

    # create backup mirrors just incase
    cp -v /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

    # if you get pgp errors
    # $ pacman -Sy archlinux-keyring
    # $ pacman-key --init
    # $ pacman-key --populate archlinux
    # $ pacman-key --refresh-keys

    # get fastest mirrors (slow way)
    # $ reflector --verbose --latest 200 --number 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

    # get fastest mirrors (fast way)
    reflector --country "${MIRROR_REGIONS}" --latest 10 --number 10 --sort rate --save /etc/pacman.d/mirrorlist

    # verify mirrors
    ${DEBUG_MODE} && \
        cat /etc/pacman.d/mirrorlist && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_arch_base() {
    echo ">> Installing Arch Base..."

    # install arch base packages
    pacstrap /mnt/ ${BASE_PACKAGES[*]} --noconfirm

    # generate /etc/fstab for automount
    genfstab -U /mnt > /mnt/etc/fstab

    # verify fstab
    ${DEBUG_MODE} && \
        cat /mnt/etc/fstab && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

# ------------------------------------------------
#   Chroot Functions
# ------------------------------------------------

set_locale() {
    echo ">> Setting Locale..."

    # select locales
    for locale in ${LOCALE_GEN[@]}; do
        sed -i "s/^#${locale}/${locale}/" /etc/locale.gen
    done

    # generate locales
    locale-gen

    # set system language
    echo "LANG=${LOCALE_SYSTEM}" > /etc/locale.conf

    # set keymap
    cat > /etc/vconsole.conf << EOF
KEYMAP=us
FONT=Lat-Terminus16
EOF

    # verify locale
    ${DEBUG_MODE} && \
        localectl list-locales && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_timezone() {
    echo ">> Setting Timezone..."

    # create symlink to timezone
    ln -sfv "/usr/share/zoneinfo/${TIMEZONE_REGION}/${TIMEZONE_CITY}" /etc/localtime

    # sync hardware clock
    hwclock --systohc -v

    # verify timezone
    ${DEBUG_MODE} && \
        ls -l /etc/localtime && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_hosts() {
    echo ">> Setting up hosts..."

    cat > /etc/hosts << EOF
127.0.0.1                                   localhost
::1                                         localhost
127.0.1.1       ${HOSTNAME}.localdomain     ${HOSTNAME}
EOF

    # verify hosts
    ${DEBUG_MODE} && \
        cat /etc/hosts && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_hostname() {
    echo ">> Setting up hostname..."

    echo "${HOSTNAME}" > /etc/hostname

    # verify hostname
    ${DEBUG_MODE} && \
        cat /etc/hostname && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_user() {
    echo ">> Adding users..."

    # add users with zsh as default shell
    useradd -m -G wheel -s /usr/bin/zsh ${USERNAME}

    # add user to sudoers
    EDITOR="sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/^# //'" visudo

    # password for user
    passwd ${USERNAME}

    # password for root
    passwd

    # verify users
    ${DEBUG_MODE} && \
        cat /etc/sudoers && cat /etc/passwd && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

edit_pacman() {
    echo ">> Edittin pacman.conf..."

    # edit pacman.conf
    sed -i "s/^#UseSyslog/UseSyslog/"                   /etc/pacman.conf
    sed -i "s/^#Color/Color/"                           /etc/pacman.conf
    sed -i "s/^#CheckSpace/CheckSpace"                  /etc/pacman.conf
    sed -i "s/^#VerbosePkgLists/VerbosePkgLists"        /etc/pacman.conf
    sed -i "s/^#ParallelDownloads/ParallelDownloads"    /etc/pacman.conf

    # add 32-bit mirrors
    sed -i '/^#\[multilib\].*/,+1 s/^#//'               /etc/pacman.conf

    # refresh pacman mirrors
    pacman -Sy

    # verify new pacman configs
    ${DEBUG_MODE} && \
        cat /etc/pacman.conf | grep "# Misc options" -A 6 && \
        cat /etc/pacman.conf | grep "\[multilib\]" -A 1 && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_cpu_microcode() {
    echo ">> Installing CPU Microcode..."

    for cpu in ${CPU[@]}; do
        case ${cpu} in
            "intel")
                echo ">> Installing Intel CPU drivers..."

                pacman -S intel-ucode --noconfirm
            ;;
        esac
    done

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_display_server() {
    echo ">> Installing Display Server..."

    pacman -S ${XORG_PACKAGES[*]} --noconfirm

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_gpu_drivers() {
    echo ">> Installing GPU drivers..."

    for gpu in ${GPU[@]}; do
        case ${gpu} in
            "intel")
                echo ">> Installing Intel GPU drivers..."

                pacman -S ${GPU_INTEL_PACKAGES[*]} --noconfirm

            cat > /etc/X11/xorg.conf.d/20-intel.conf << EOF
# prevent screen tearing for intel
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
EndSection
EOF
            ;;

            "nvidia")
                echo ">> Installing Nvidia GPU drivers..."
                
                pacman -S ${GPU_NVIDIA_PACKAGES[*]} --noconfirm

                # generate nvidia xorg
                nvidia-xconfig

                # add nvidia hook
                cat > /etc/pacman.d/hooks/nvidia.hook << EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=nvidia-lts
Target=nvidia-dkms
Target=nvidia-utils
Target=lib32-nvidia-utils
Target = linux
Target = linux-lts
Target = linux-hardened
Target = linux-zen

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec = /bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

                # enable power saving
                systemctl enable nvidia-suspend
                systemctl enable nvidia-hibernate

                # early KMS will break hibernation with this enabled
                # systemctl enable nvidia-resume

                # add to kernel parameter to preserve memory after suspend
                cat > /etc/modprobe.d/nvidia-power-management.conf << EOF
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath="/var/tmp
EOF
            ;;

        esac
    done

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_desktop_env() {
    echo ">> Installing Desktop Environment..."

    pacman -S ${DE[*]} --noconfirm

    # copy over default xinitrc
    cp /etc/X11/xinit/xinitrc /home/${USERNAME}/.xinitrc

    # comment out xorg and xorg-apps
    sed -i '/^twm .*/,+4 s/^/#/' /home/${USERNAME}/.xinitrc

    # add another de to run with 'startx'
    printf "\nexec i3\n" >> /home/${USERNAME}/.xinitrc
    echo "#exec xfce4-session" >> /home/${USERNAME}/.xinitrc
    echo "#exec gnome-session" >> /home/${USERNAME}/.xinitrc

    # change owner of .xinitrc
    chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.xinitrc

    # verify .xinitrc
    ${DEBUG_MODE} && \
        cat /home/${USERNAME}/.xinitrc && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_basic_packages() {
    echo ">> Installing Basic Packages..."

    pacman -S ${ADDITIONAL_PACKAGES[*]} --noconfirm

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_aur() {
    echo ">> Installing AUR..."

    su - ${USERNAME} << EOF
cd && git clone https://aur.archlinux.org/yay
cd yay && makepkg -si --noconfirm
cd .. && rm -rf yay
exit
EOF

    # install AUR packages
    yay -Sy ${AUR_PACKAGES[*]} --noconfirm

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_bootloader() {
    echo ">> Installing Bootloader..."

    case ${BOOTLOADER} in
        "refind")
            echo ">> Installing rEFIND Bootloader..."

            pacman -S refind --noconfirm

            refind-install

            CRYPT_UUID="$(lsblk -o NAME,UUID | grep ${ROOT_PARTITION#/dev/} | awk '{print $2}')"
            RESUME_OFFSET="$(btrfs inspect-internal map-swapfile -r /mnt/.swapvol/swapfile)"

            if [[ ${GPU[@]} =~ "nvidia" ]]; then
                # check if modeset worked:
                # $ cat /sys/module/nvidia_drm/parameters
                NVIDIA_KMS_PARAMETERS="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"
            fi

            cat > /mnt/boot/EFI/refind/refind.conf << EOF
menuentry "Arch Linux" {
    icon        /EFI/refind/icons/os_arch.png
    volume      "CRYPT_ROOT"
    loader      /vmlinuz-linux
    initrd      /initramfs-linux.img
    options     "rd.luks.name=${CRYPT_UUID}=crypt root=/dev/mapper/crypt rootflags=subvol=@ resume=/dev/mapper/crypt resume_offset=${RESUME_OFFSET} rw initrd=/intel-ucode.img initrd=/initramfs-linux.img ${NVIDIA_KMS_PARAMETERS}"

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
EOF

            # verify refind configs
            ${DEBUG_MODE} && \
                cat /boot/EFI/refind/refind.conf && \
                printf "\nPress Enter to continue...\n\n"; read; clear
        ;;
    esac
}

misc_configs() {
    echo ">> Setting up Reflector..."

    cat > /etc/NetworkManager/conf.d/wifi_backend.conf << EOF
[device]
wifi.backend=iwd
EOF

    echo ">> Setting up Reflector..."

    mkdir -p /etc/xdg/reflector

    # mirror configs
    cat > /etc/xdg/reflector/reflector.conf << EOF
--country "${MIRROR_REGIONS}" \
--latest 10 \
--number 10 \
--sort rate \
--save /etc/pacman.d/mirrorlist
EOF

    echo ">> Pruning .snapshots in /etc/updatedb.conf..."

    # prevent snapshot slowdowns
    echo 'PRUNENAMES = ".snapshots"' >> /etc/updatedb.conf

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

setup_hooks() {
    echo ">> Setting up Systemd Hooks..."

    mkdir /etc/pacman.d/hooks

    # sign kernel initramfs after every rebuild update
    cat > /etc/pacman.d/hooks/999-sign_kernel_for_secureboot.hook << EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux
Target = linux-lts
Target = linux-hardened
Target = linux-zen

[Action]
Description = Signing kernel with Machine Owner Key for Secure Boot
When = PostTransaction
Exec = /usr/bin/find /boot/ -maxdepth 1 -name 'vmlinuz-*' -exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null | /usr/bin/grep -q "signature certificates"; then /usr/bin/sbsign --key /etc/refind.d/keys/refind_local.key --cert /etc/refind.d/keys/refind_local.crt --output {} {}; fi' ;
Depends = sbsigntools
Depends = findutils
Depends = grep
EOF

    # sign after every rEFIND update
    cat > /etc/pacman.d/hooks/refind.hook << EOF
[Trigger]
Operation=Upgrade
Type=Package
Target=refind

[Action]
Description = Updating rEFInd on ESP
When=PostTransaction
Exec=/usr/bin/refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys
EOF

    # refresh cache after zsh update
    cat > /etc/pacman.d/hooks/zsh.hook << EOF
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Path
Target = usr/bin/*

[Action]
Depends = zsh
When = PostTransaction
Exec = /usr/bin/install -Dm644 /dev/null /var/cache/zsh/pacman
EOF

    # verify systemd hooks
    ${DEBUG_MODE} && \
        ls -l /etc/pacman.d/hooks && \
        printf "\nPress Enter to continue...\n\n"; read; clear

}

enable_systemd_units() {
    echo ">> Enabling Systemd Startups..."

    systemctl enable ${SYSTEMD_STARTUPS[*]}

    ${DEBUG_MODE} && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

rebuild_initramfs() {
    echo ">> Rebuilding Initramfs..."

    # replace MODULES array
    sed -i "s/^MODULES=.*/MODULES=( ${MODULES[*]} )/" /etc/mkinitcpio.conf

    # replace HOOKS array
    sed -i "s/^HOOKS=.*/HOOKS=( ${HOOKS[*]} )/" /etc/mkinitcpio.conf

    # rebuild
    mkinitcpio -P

    # verify modules and hooks
    ${DEBUG_MODE} && \
        cat /etc/mkinitcpio.conf | grep '^MODULES=.*' && \
        cat /etc/mkinitcpio.conf | grep '^HOOKS=.*' && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

# ------------------------------------------------
#   Main
# ------------------------------------------------

main() {

    # before anything, for safety ROOT_PARTITION must be specified
    if [[ -z {ROOT_PARTITION} ]]; then
        echo ">> ROOT_PARTITION must be specified in config! EXITING..."
        exit
    fi

    # run pre-chroot part of the script
    if [[ $# -eq 0 ]]; then

        echo "******** Starting Arch Install... ********"

        # setup filesystem
        setup_luks
        setup_btrfs
        setup_swapfile

        # update mirror and install packages
        update_mirrorlist
        install_arch_base

        # copy over this script to /mnt
        cp -v "${FULL_PATH}" /mnt/home

        # chroot and execute this script using --chroot parameter
        arch-chroot /mnt sh "/home/${SCRIPT_NAME}" --chroot

        # clean up copied script once chroot functions are complete
        rm "/mnt/home/${SCRIPT_NAME}"

        exit

        echo "******** Arch Install Completed! ********"
    
    # run chroot part of the script
    elif [[ ${1} == "--chroot" ]]; then
        echo ">> Starting chroot..."
    
        # set basic configs
        set_locale
        set_timezone
        set_hosts
        set_hostname
        set_user
        edit_pacman

        # install drivers and more packages
        install_cpu_microcode
        install_display_server
        install_gpu_drivers
        install_desktop_env
        install_basic_packages
        install_aur
        install_bootloader

        # other configs
        misc_configs
        setup_hooks
        enable_systemd_units

        # edit and rebuild kernel image
        rebuild_initramfs

        # quick fix for btrfs fstab (bug) - TODO
        # btrfs_quick_fix

        echo ">> Finished chroot!"

    fi

}

# run main
main $@