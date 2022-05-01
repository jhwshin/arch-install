#!/usr/bin/env bash

# ==============================================================================
#   Arch Linux - Install Script by jhwshin
# ==============================================================================

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#       SETUP VARS - START EDIT HERE
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

# verify result after each setup section
VERIFY=true

# prompt after each section
INTERACTIVE_SHELL=true

# dualboot use windows local time
DUALBOOT_TIME_FIX=true

# create and mount swapfile for hibernation
SETUP_SWAPFILE=true
SWAP_SIZE_MB=17408      # 16GB + 1GB = 17GB

# --------------------------------------
#       PRE-CHROOT
# --------------------------------------

# Reflector - mirror regions
#   `$  reflector --list-countries`
REFLECTOR_REGION=(
    "US"
)

INSTALL_PACKAGES=(
    base base-devel
    linux-firmware
    linux-api-headers
    linux linux-headers
    linux-lts linux-lts-headers             # longterm support
    git
    nano nano-syntax-highlighting           # basic cli editor
    openssh                                 # ssh
    alsa-utils pavucontrol                  # audio
    networkmanager network-manager-applet   # network
    bluez bluez-utils blueman               # bluetooth
    xdg-utils xdg-user-dirs                 # xdg
)

SYSTEMCTL_ENABLE=(
    sshd
    NetworkManager
    bluetooth
)

# --------------------------------------
#       CHROOT
# --------------------------------------

# Locales
#   `$  localectl list-locales`
LOCALES_GENERATE=(
    "en_US.UTF-8 UTF-8"
)
LOCALE_SYSTEM="en_US.UTF-8"

# Timezone
#   `$  ls /usr/share/zoneinfo/<REGION>/<CITY>`
TIMEZONE_REGION="<REGION>"
TIMEZONE_CITY="<CITY>"

# Hostname
HOSTNAME="<HOSTNAME>"
USERNAME="<USER>"

# Drivers
INSTALL_CPU="intel"             # intel | amd
INSTALL_GPU="intel"             # intel | nvidia
INSTALL_BOOTLOADER="refind"     # refind | grub

# Desktop Environment (GUI)
INSTALL_DE=(
    i3 dmenu
    xfce4 xfce4-goodies
    #gnome gnome-extra
    #cinnamon
)

# Display Manager (Login)
INSTALL_DM=(
    gdm
)

# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#       SETUP VARS - END EDIT HERE
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# --------------------------------------
#       DEFAULT PACKAGE LIST
# --------------------------------------

# CPU
PKG_CPU_INTEL="intel-ucode"
PKG_CPU_AMD="amd-ucode"

# GPU
PKG_GPU_INTEL=(
    xf86-video-intel
    mesa lib32-mesa
    vulkan-intel lib32-vulkan-intel
)
PKG_GPU_NVIDIA=(
    nvidia nvidia-lts nvidia-dkms
    nvidia-utils lib32-nvidia-utils
    nvidia-settings
)
# PKG_GPU_VM=(
#     mesa lib32-mesa
#     virtualbox-guest-utils
# )

# BOOTLOADER
PKG_BOOTLOADER_REFIND="refind"
PKG_BOOTLOADER_GRUB=(
    grub
    efibootmgr
    os-prober
)

# --------------------------------------
#       HELPER FUNCTIONS
# --------------------------------------

SCRIPT_NAME="$(basename "${0}")"
SCRIPT_PATH="$(realpath "${0}")"

# interactive prompt
prompt() {
    if [[ ${INTERACTIVE_SHELL} = true ]]; then
        printf "Press ANY key to continue.\n"
        read
        clear
    fi
}

# --------------------------------------
#       PRE-CHROOT FUNCTIONS
# --------------------------------------

update_mirrors() {
    printf ">> Updating mirrors...\n\n"

    # backup mirrors
    cd /etc/pacman.d
    cp -v mirrorlist mirrorlist.bak

    # update keys (takes very long) - only use if you have package key issues
    #pacman -Syy archlinux-keyring --noconfirm
    #pacman-key --refresh-keys

    # update mirrors to fastest given region location
    reflector --verbose --country $(echo ${REFLECTOR_REGION[*]} | tr ' ' ',') --latest 40 --sort rate --save mirrorlist

    cd

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/pacman.d/mirrorlist
    fi

    printf "\n\n>> Mirrors updated!\n\n"
    prompt
}

install_packages() {
    printf ">> Installing Arch pacakges...\n\n"

    pacstrap /mnt ${INSTALL_PACKAGES[*]}

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /mnt/var/log/pacman.log | head -n 1
    fi

    printf "\n\n>> Arch packages installed!\n\n"
    prompt
}

generate_fstab() {
    printf ">> Generating fstab...\n\n"

    # TODO - change uuid to label?
    genfstab -U /mnt > /mnt/etc/fstab

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /mnt/etc/fstab
    fi

    printf "\n\n>> Fstab generated!\n\n"
    prompt
}

start_chroot() {
    printf ">> Entering chroot...\n\n"

    # copy this script over to new mnt root
    cp -v ${SCRIPT_PATH} /mnt/home

    # run this script with as root as new mnt
    arch-chroot /mnt sh /home/${SCRIPT_NAME} --chroot

    # clean up - remove he copied script after install
    rm /mnt/home/${SCRIPT_NAME}

    printf "\n>> Leaving chroot!\n\n"
    prompt
}

# --------------------------------------
#       CHROOT FUNCTIONS
# --------------------------------------

set_locale() {
    printf ">> Setting locale...\n\n"

    # uncomment locales
    for locale in "${LOCALES_GENERATE[@]}"; do
        sed -i "/^#${locale}/ s/^#//" /etc/locale.gen
    done

    # generate locales
    locale-gen

    # set env variable system locale
    echo "LANG=${LOCALE_SYSTEM}" > /etc/locale.conf

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/locale.conf
    fi

    printf "\n\n>> Finished setting locales!\n\n"
    prompt
}

set_timezone() {
    printf ">> Setting timezone ${TIMEZONE_REGION}/${TIMEZONE_CITY}...\n\n"

    # symlink timezone
    ln -sv /usr/share/zoneinfo/${TIMEZONE_REGION}/${TIMEZONE_CITY} /etc/localtime

    # sync hardware clock
    hwclock --systohc -v

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        ls -la /etc/localtime
    fi

    printf "\n\n>> Finished setting timezone!\n\n"
    prompt
}

set_hostname() {
    printf ">> Setting hostname ${HOSTNAME}...\n\n"

    echo "${HOSTNAME}" > /etc/hostname

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/hostname
    fi

    printf "\n\n>> Finished setting hostname!\n\n"
    prompt
}

set_hosts() {
    printf ">> Setting hosts...\n\n"

    # loopback ip to localhost in ipv4 and ipv6
    echo "127.0.0.1        localhost" >> /etc/hosts
    echo "::1              localhost" >> /etc/hosts

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/hosts
    fi

    printf "\n\n>> Finished setting hosts!\n\n"
    prompt
}

set_root_passwd() {
    printf ">> Setting root passwd...\n\n"

    passwd

    printf "\n\n>> Finished setting root passwd!\n\n"
    prompt
}

set_user() {
    printf ">> Creating user ${USERNAME}...\n\n"

    # create user and add to wheel group
    useradd -m ${USERNAME} -G wheel

    passwd ${USERNAME}

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/passwd | grep -E "^${USERNAME}:"
    fi

    printf "\n\n>> Finished setting hosts!\n\n"
    prompt
}


set_sudoer() {
    printf ">> Setting sudoer...\n\n"

    # uncomment and add wheel group to sudoers
    EDITOR="sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/^# //'" visudo

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/sudoers | grep "%wheel ALL=(ALL:ALL) ALL" -C 1
    fi

    printf "\n>> Finished setting hosts!\n\n"
    prompt
}

edit_pacman_conf() {
    printf ">> Editing pacman.conf...\n\n"

    # change misc options in pacman
    sed -i "/^#UseSyslog/ s/^#//" /etc/pacman.conf
    sed -i "/^#Color/ s/^#//" /etc/pacman.conf
    sed -i "/^#VerbosePkgLists/ s/^#//" /etc/pacman.conf
    sed -i "/^#ParallelDownloads/ s/^#//" /etc/pacman.conf

    # add 32-bit source
    sed -i '/^#\[multilib\].*/,+1 s/^#//' /etc/pacman.conf

    # update new sources
    pacman -Syy --noconfirm

    if [[ ${VERIFY} = true ]]; then
        printf ">> Verification:\n\n"
        cat /etc/pacman.conf | grep "# Misc options" -A 6
        echo ""
        cat /etc/pacman.conf | grep "\[multilib\]" -A 1
    fi

    printf "\n>> Finished setting pacman.conf!\n\n"
    prompt
}

create_swapfile() {
    printf ">> Setting up swapfile...\n\n"

    # create new /swapfile given size
    dd if=/dev/zero of=/swapfile bs=1M count=${SWAP_SIZE_MB} status=progress

    # change permission
    chmod 600 /swapfile

    # make and turn on swap
    mkswap /swapfile
    swapon /swapfile

    # add resume to mkinitcpio to generate new ramdisk image
    sed -i "s/^HOOKS=.*udev/& resume/" /etc/mkinitcpio.conf

    # not required since it mkinitcpio runs after this function regardless
    #mkinitcpio -P

    # add swapfile fstab to automount
    echo "/swapfile     none    swap    defaults    0   0" >> /etc/fstab

    printf "\n>> Finished setting up swapfile!\n\n"
    prompt
}

make_initramfs() {
    printf ">> Creating initram disk...\n\n"

    mkinitcpio -P

    printf "\n>> Finished creating initram disk!\n\n"
    prompt
}

install_cpu_microcode() {
    printf ">> Installing CPU microcode ${INSTALL_CPU}...\n\n"

    case ${INSTALL_CPU} in
    "intel")
        pacman -S ${PKG_CPU_INTEL} --noconfirm
        ;;
    "amd")
        pacman -S ${PKG_CPU_AMD} --noconfirm
        ;;
    esac

    printf "\n>> Finished installing CPU microcode!\n\n"
    prompt
}

install_gpu_drivers() {
    printf ">> Installing GPU drivers ${INSTALL_GPU}...\n\n"

    pacman -S xorg xorg-apps --noconfirm

    case ${INSTALL_GPU} in
        "intel")
            pacman -S ${PKG_GPU_INTEL[*]} --noconfirm
        ;;
        "nvidia")
            pacman -S ${PKG_GPU_NVIDIA[*]} --noconfirm

            # generate nvidia xorg config file
            nvidia-xconfig

            # pacman hook to rebuild initramfs when linux or nvidia updates
            nvidia_systemd="[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=nvidia-lts
Target=nvidia-dkms
Target=linux
# Change the linux part above and in the Exec line if a different kernel is used

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
"

            printf "${nvidia_systemd}" > /etc/pacman.d/hooks/nvidia.hooks
        ;;
        # TODO: Virtual Machine
        # "vm")
        # pacman -S ${PKG_GPU_VM} --noconfirm

        # #   enable virtualbox guest
        # systemctl enable vboxservice
        # usermod -G vboxsf -a ${USERNAME}
        # ;;
    esac

    printf "\n>> Finished installing GPU drivers!\n\n"
    prompt
}

install_bootloader() {
    printf ">> Installing bootloader...${INSTALL_BOOTLOADER}\n\n"

    # generate resume parameters for hibernation
    resume_paramters=""
    root_part=$(mount | grep -oP '(?<=^)/dev/.*(?= on / )')
    if [[ ${SETUP_SWAPFILE} = true ]]; then
        # swap offset location required for /swapfile
        swap_offset=$(filefrag -v /swapfile | sed -n 4p | awk '{print $4}' | grep -o [0-9]*)

        # final kernel parameter to add to bootloader
        resume_parameters="resume=${root_part} resume_offset=${swap_offset}"
    fi

    case ${INSTALL_BOOTLOADER} in
        "refind")
            pacman -S ${PKG_BOOTLOADER_REFIND} --noconfirm

            refind-install

            # fix refind bug - add rootpart and resume parameters if swap is enabled
            printf -- "\"Boot with standard options\" \"root=${root_part} rw add_efi_memmap ${resume_parameters}\"\n" >/boot/refind_linux.conf
            printf -- "\"Boot to single-user mode\" \"root=${root_part}\" add_efi_memmap single\"\n" >>/boot/refind_linux.conf
            printf -- "\"Boot with minimal options\" \"root=${root_part}\"\n" >>/boot/refind_linux.conf

        ;;
        "grub")
            pacman -S ${PKG_BOOTLOADER_GRUB[*]} --noconfirm

            grub-install

            # if swap is enabled, add kernel resume to kernel parameters
            if [[ ${SETUP_SWAPFILE} = true ]]; then
                sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=/& ${resume_parameters}/" /etc/default/grub
            fi

            # generate grub config
            grub-mkconfig -o /boot/grub/grub.cfg
        ;;
    esac

    printf "\n>> Finished installing bootloader!\n\n"
    prompt
}

install_desktop_env() {
    printf ">> Installing desktop environment...\n\n"

    pacman -S ${INSTALL_DE[*]} --noconfirm

    printf "\n>> Finished installing environment!\n\n"
    prompt
}

install_display_manager() {
    printf ">> Installing display manager...\n\n"

    pacman -S ${INSTALL_DM} --noconfirm

    case ${INSTALL_DM} in
        "gdm")
            systemctl enable gdm
        ;;
    esac

    printf "\n>> Finished installing display manager!\n\n"
    prompt
}

enable_systemctl() {
    printf ">> Enabling application autostart...\n\n"

    # autostart processes in background
    for cmd in ${SYSTEMCTL_ENABLE[@]}; do
        systemctl enable ${cmd}
    done

    printf "\n>> Finished setting up autostart!\n\n"
    prompt
}

dualboot_time_fix() {
    printf ">> Fixing dualboot time...\n\n"

    # windows dualboot time fix - use local time
    timedatectl set-local-rtc 1 --adjust-system-clock
    hwclock --systohc --localtime

    printf "\n!! Make sure to disable 'Set time automatically' in Windows."

    printf "\n>> Finished dualboot time fix!\n\n"
    prompt
}

# ======================================
#       MAIN
# ======================================

if [[ ${1} != "--chroot" ]]; then

    printf -- "\n======================================\n"
    printf    "     STARTING ARCH INSTALLER..."
    printf -- "======================================\n"

    update_mirrors
    install_packages
    generate_fstab
    start_chroot

    printf -- "\n======================================\n"
    printf    "     FINISHED ARCH INSTALLER!"
    printf -- "======================================\n"

# # ======================================
# #       CHROOT
# # ======================================

else

    # basic configurations
    set_locale
    set_timezone
    set_hostname
    set_hosts
    set_root_passwd
    set_user
    set_sudoer
    edit_pacman_conf

    if [[ ${SETUP_SWAPFILE} = true ]]; then
        create_swapfile
    fi

    make_initramfs

    # install drivers and de
    install_cpu_microcode
    install_gpu_drivers
    install_bootloader
    install_desktop_env
    install_display_manager

    # install and run additional apps
    enable_systemctl
    dualboot_time_fix

fi
