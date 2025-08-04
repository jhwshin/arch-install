#!/usr/bin/env bash

set_locale() {
    echo ">> Setting Locale..."

    # generate locales
    for locale in  ${LOCALE_GEN[@]}; do
        sed -i "s/^#${locale}/${locale}/" /etc/locale.gen
    done

    locale-gen

    # setting locale
    echo "LANG=${LOCALE_SYSTEM}" > /etc/locale.conf

    "${VERIFY}" && \
        tail -v -n +1 /etc/locale.conf && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

set_timezone() {
    echo ">> Setting Timezone..."

    # symlink timezone
    ln -sfv "/usr/share/zoneinfo/${TIMEZONE_REGION}/${TIMEZONE_CITY}" /etc/localtime

    # sync system clock to hardware clock
    hwclock --systohc -v

    "${VERIFY}" && \
        ls -l /etc/localtime && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

set_hosts() {
    echo "Setting Hosts Resolution..."

    # add host's localdomain
    echo "127.0.1.1        ${HOSTNAME}.localdomain ${HOSTNAME}" >> /etc/hosts

    "${VERIFY}" && \
        tail -v -n +1 /etc/hosts && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

set_hostname() {
    echo ">> Setting Hostname..."

    echo "${HOSTNAME}" > /etc/hostname

    "${VERIFY}" && \
        tail -v -n +1 /etc/hostname && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

set_users() {
    echo ">> Adding User: ${USERNAME}..."

    # create user and add them to wheel group
    useradd -m -G wheel -s /usr/bin/bash "${USERNAME}"

    # add wheel group to sudoers
    EDITOR="sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/^# //'" visudo

    # set password for user
    passwd "${USERNAME}"

    # set password for root
    passwd

    "${VERIFY}" && \
        tail -v -n +1 /etc/sudoers /etc/passwd && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

modify_pacman_conf() {
    echo ">> Modifying Pacman Config..."

    # enable useful settings
    sed -i "s/^#UseSyslog/UseSyslog/"                   /etc/pacman.conf
    sed -i "s/^#Color/Color/"                           /etc/pacman.conf
    sed -i "s/^#CheckSpace/CheckSpace/"                 /etc/pacman.conf
    sed -i "s/^#VerbosePkgLists/VerbosePkgLists/"       /etc/pacman.conf
    sed -i "s/^#ParallelDownloads/ParallelDownloads/"   /etc/pacman.conf

    # enable 32-bit mirrors
    sed -i '/^#\[multilib\].*/,+1 s/^#//'               /etc/pacman.conf

    # refresh mirrors
    pacman -Syy

    "${VERIFY}" && \
        echo "==> /etc/pacman.conf <==" && \
        grep "# Misc options" -A 6 /etc/pacman.conf && \
        grep "\[multilib\]" -A 1 /etc/pacman.conf && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_cpu_microcode() {
    echo ">> Installing CPU Microcode..."

    case ${CPU} in
        "amd")
            echo ">> Installing [AMD] CPU Microcode..."

            pacman -S ${CPU_AMD_PKGS[*]} --noconfirm
        ;;
        "intel")
            echo ">> Installing [Intel] CPU Microcode..."
            
            pacman -S ${CPU_INTEL_PKGS[*]} --noconfirm
        ;;
        # vm?
    esac

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_gpu_drivers() {
    echo ">> Installing GPU Drivers..."

    # install integrated GPU drivers
    case ${CPU} in
        "amd")
            echo ">> Installing Integrated [AMD] GPU Drivers..."

            pacman -S ${GPU_AMD_PKGS[*]} --noconfirm

            chroot_copy_config amd
        ;;
        "intel")
            echo ">> Installing Integrated [Intel] CPU Drivers..."

            pacman -S ${GPU_INTEL_PKGS[*]} --noconfirm

            chroot_copy_config intel
        ;;
        # vm?
    esac

    # install discrete GPU drivers
    for gpu in ${GPU[@]}; do
        case ${gpu} in
            "nvidia")
                echo ">> Installing [Nvidia] GPU Drivers..."
                
                pacman -S ${GPU_NVIDIA_PKGS[*]} --noconfirm

                chroot_copy_config nvidia
            ;;
            # TODO
            "amd")
                echo ">> AMD GPU DRIVERS NOT YET IMPLEMENTED !!"
            ;;
        esac
    done

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_display_servers() {
    echo ">> Installing Display Server..."

    for ds in ${DISPLAY_SERVERS[@]}; do
        case ${ds} in
            "x11")
                echo ">> Installing [X11] Display Server..."

                pacman -S ${DISPLAY_SERVER_X11_PKGS[*]} --noconfirm
            ;;
            # TODO
            "wayland")
                echo ">> WAYLAND NOT YET IMPLEMENTED !!"
            ;;
        esac
    done

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_bootloader() {
    echo ">> Installing Bootloader..."

    case ${BOOTLOADER} in
        "grub")
            echo "GRUB NOT YET IMPLEMENTED !!"
            # echo ">> Installing [GRUB] Bootloader..."

            # pacman -S ${BOOTLOADER_GRUB_PKGS[*]} --noconfirm

            # "${VERIFY}" && \
            # printf "\n Press [ENTER] to continue...\n\n" && read && clear
        ;;
        "refind")
            echo ">> Installing [rEFIND] Bootloader..."
            
            pacman -S ${BOOTLOADER_REFIND_PKGS[*]} --noconfirm

            refind-install

            chroot_copy_config refind

            "${VERIFY}" && \
                tail -v -n +1 /boot/EFI/refind/refind.conf && \
            printf "\n Press [ENTER] to continue...\n\n" && read && clear
        ;;
    esac
}

install_desktop_environments() {
    echo ">> Installing Desktop Environments..."

    pacman -S ${DESKTOP_ENVIRONMENT_PKGS[*]} --noconfirm

    # copy over default xinitrc
    cp /etc/X11/xinit/xinitrc "/home/${USERNAME}/.xinitrc"

    # disable twm and apps
    sed -i '/^\"$twm\" .*/,+4 s/^/#/' "/home/${USERNAME}/.xinitrc"

    # add preferred de or wm (runs with startx)
    printf "\nexec i3\n" >> "/home/${USERNAME}/.xinitrc"
    echo "#exec xfce4-session" >> "/home/${USERNAME}/.xinitrc"
    echo "#exec gnome-session" >> "/home/${USERNAME}/.xinitrc"

    # change ownership
    chown ${USERNAME}:${USERNAME} "/home/${USERNAME}/.xinitrc"

    "${VERIFY}" && \
        tail -v -n +1 "/home/${USERNAME}/.xinitrc" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_basic_packages() {
    echo ">> Installing Basic Packages..."

    pacman -S ${BASIC_PKGS[*]} --noconfirm

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

enable_systemd_services() {
    echo ">> Enabling Systemd Services..."

    systemctl enable ${SYSTEMD_SERVICES[*]}

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_aur_packages() {
    echo ">> Installing [yay] AUR Package Manager..."

    su - ${USERNAME} << EOF
cd && git clone https://aur.archlinux.org/yay
cd yay && makepkg -si --noconfirm
cd .. && rm -rf yay
exit
EOF

    yay -Syy ${AUR_PKGS[*]} --noconfirm

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

setup_snapper() {
    echo ">> Setting up Snapper..."

    pacman -S snapper snap-pac --noconfirm

    # snapper redundant root snapshot config fix
    umount -v /.snapshots && rmdir -v /.snapshots
    snapper -vc root create-config /
    btrfs su delete /.snapshots
    mkdir -v /.snapshots && mount -av

    # create configs for cow subvolumes
    snapper -vc home create-config /home
    snapper -vc root create-config /root
    snapper -vc srv create-config /srv

    # copy over snapper configs
    chroot_copy_config snapper

    # prevent btrfs snapshot slowdowns
    echo ">> Pruning .snapshots in /etc/updatedb.conf..."
    echo 'PRUNENAMES = ".snapshots"' >> /etc/updatedb.conf

    # fix one of these?
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-boot.timer
    systemctl enable snapper-cleanup.timer

    # TODO
    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

misc_configs() {
    echo ">> Copying Configurations..."

    echo ">> Copying Reflector Config..."
    chroot_copy_config reflector

    echo ">> Copying ZSH Hook..."
    chroot_copy_config zsh

    # TODO
    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

setup_refind_secureboot() {

    # install shim (intermediary bootloader signed by Microsoft)
    # install sbsigntool to sign refind with Machine Owner Key (MOK)
    yay -S shim-signed sbsigntools

    # shim is copied into EFI partition /boot/EFI/refind/shimx64.efi
    # then the refind binary is renamed to grubx64.efi (since shim chainloads to grub)
    # then the local key pair is generated and signs refind
    # finally the pub key is enrolled into MOKs
    refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys

    # after reboot, enable secure boot then, MOK Manager will prompt to enrol the crt in /boot/EFI/refind/refind_local.cer
    # kernel is signed automatically when initramfs is rebuilt thanks to copied script in refind config
    # /etc/initcpio/post/kernel-sbsign
}

build_initramfs() {
    echo ">> Generating Initramfs..."

    # add new MODULES array
    sed -i "/^MODULES/ { 
        s/^/# /
        a\
MODULES=( ${INITRAMFS_MODULES[*]} )
        }" /etc/mkinitcpio.conf

    # add new HOOKS array
    sed -i "/HOOKS/ { 
        s/^/#/ 
        a\
HOOKS=( ${INITRAMFS_HOOKS[*]} )
        }" /etc/mkinitcpio.conf

    mkinitcpio -P

    "${VERIFY}" && \
        echo "==> /etc/mkinitcpio.conf <==" && \
        grep -E "^MODULES|^HOOKS" /etc/pacman.conf && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}