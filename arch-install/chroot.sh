set_locale() {
    echo ">> Setting Locale..."

    for locale in ${LOCALE_GEN[@]}; do
        sed -i "s/^#${locale}/${locale}/" /etc/locale.gen
    done

    locale-gen

    echo "LANG=${LOCALE_SYSTEM}" > /etc/locale.conf

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/locale.conf | grep "${LOCALE_SYSTEM}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_timezone() {
    echo ">> Setting Timezone..."

    # symlink timezone
    ln -sfv "/usr/share/zoneinfo/${TIMEZONE_REGION}/${TIMEZONE_CITY}" /etc/localtime

    # sync hardware clock
    hwclock --systohc -v

    # verify
    "${INTERACTIVE_MODE}" && \
        ls -l /etc/localtime && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_hosts() {
    echo ">> Setting up hosts..."

    echo "${HOSTS_CONF}" > /etc/hosts

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/hosts && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_hostname() {
    echo ">> Setting up hostname..."

    echo "${HOSTNAME}" > /etc/hostname

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/hostname && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_users() {
    echo ">> Adding users..."

    # add users with zsh as default shell
    useradd -m -G wheel -s /usr/bin/zsh "${USERNAME}"

    # add wheel group to sudoers
    EDITOR="sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/^# //'" visudo

    passwd "${USERNAME}"    # set password for user
    passwd                  # set password for root

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/sudoers && cat /etc/passwd && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

edit_pacman_conf() {
    echo ">> Editing pacman.conf..."

    # edit pacman.conf
    sed -i "s/^#UseSyslog/UseSyslog/"                   /etc/pacman.conf
    sed -i "s/^#Color/Color/"                           /etc/pacman.conf
    sed -i "s/^#CheckSpace/CheckSpace/"                 /etc/pacman.conf
    sed -i "s/^#VerbosePkgLists/VerbosePkgLists/"       /etc/pacman.conf
    sed -i "s/^#ParallelDownloads/ParallelDownloads/"   /etc/pacman.conf

    # add 32-bit mirrors
    sed -i '/^#\[multilib\].*/,+1 s/^#//'               /etc/pacman.conf

    # refresh pacman mirrors
    pacman -Sy

    # verify
    "${INTERACTIVE_MODE}" && \
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

    # verify
    "${INTERACTIVE_MODE}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_display_servers() {
    echo ">> Installing Display Server..."

    pacman -S ${XORG_PACKAGES[*]} --noconfirm

    # verify
    "${INTERACTIVE_MODE}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_gpu_drivers() {
    echo ">> Installing GPU drivers..."

    for gpu in ${GPU[@]}; do
        case ${gpu} in
            "intel")
                echo ">> Installing Intel GPU drivers..."

                pacman -S ${GPU_INTEL_PACKAGES[*]} --noconfirm

                echo "${INTEL_XORG_CONF}" > "/etc/X11/xorg.conf.d/20-intel.conf"
            ;;
            "nvidia")
                echo ">> Installing Nvidia GPU drivers..."
                
                pacman -S ${GPU_NVIDIA_PACKAGES[*]} --noconfirm

                # generate nvidia xorg
                nvidia-xconfig

                # add nvidia hook
                mkdir -p /etc/pacman.d/hooks
                echo "${NVIDIA_HOOK}" > "/etc/pacman.d/hooks/nvidia.hook"
            ;;
        esac
    done

    # verify
    "${INTERACTIVE_MODE}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_bootloader() {
    echo ">> Installing Bootloader..."

    case ${BOOTLOADER} in
        "refind")
            echo ">> Installing rEFIND Bootloader..."

            pacman -S refind --noconfirm

            refind-install

            # hooks for secureboot
            mkdir -p /etc/pacman.d/hooks
            echo "${MOKS_HOOK}" > "/etc/pacman.d/hooks/999-sign_kernel_for_secureboot.hook"
            echo "${REFIND_HOOK}" > "/etc/pacman.d/hooks/refind.hook"

        # verify
        "${INTERACTIVE_MODE}" && \
            cat /boot/EFI/refind/refind.conf && \
            printf "\nPress Enter to continue...\n\n"; read; clear
        ;;
    esac
}

install_desktop_environments() {
    echo ">> Installing Desktop Environment..."

    pacman -S ${DESKTOP_ENVIRONMENTS[*]} --noconfirm

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

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /home/${USERNAME}/.xinitrc && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_basic_packages() {
    echo ">> Installing Basic Packages..."

    pacman -S ${BASIC_PACKAGES[*]} --noconfirm

    # enable auto startup
    systemctl enable ${SYSTEMD_STARTUPS[*]}

    # verify
    "${INTERACTIVE_MODE}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_aur_packages() {
    echo ">> Installing AUR..."

    su - ${USERNAME} << EOF
cd && git clone https://aur.archlinux.org/yay
cd yay && makepkg -si --noconfirm
cd .. && rm -rf yay
exit
EOF

    # install AUR packages
    yay -Sy ${AUR_PACKAGES[*]} --noconfirm

    # verify
    "${INTERACTIVE_MODE}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

misc_configs() {
    echo ">> Setting up Reflector..."
    mkdir -p /etc/xdg/reflector
    echo "${REFLECTOR_CONF}" > "/etc/xdg/reflector/reflector.conf"

    # prevent btrfs snapshot slowdowns
    echo ">> Pruning .snapshots in /etc/updatedb.conf..."
    echo 'PRUNENAMES = ".snapshots"' >> /etc/updatedb.conf

    # hooks zsh updates
    echo ">> Setting up ZSH hooks..."
    echo "${ZSH_HOOK}" > "/etc/pacman.d/hooks/zsh.hook"

    # verify
    "${INTERACTIVE_MODE}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

build_initramfs() {
    echo ">> Rebuilding Initramfs..."

    # replace MODULES array
    sed -i "s/^MODULES=.*/MODULES=( ${MODULES[*]} )/" /etc/mkinitcpio.conf

    # replace HOOKS array
    sed -i "s/^HOOKS=.*/HOOKS=( ${HOOKS[*]} )/" /etc/mkinitcpio.conf

    # rebuild initramfs
    mkinitcpio -P

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/mkinitcpio.conf | grep '^MODULES=.*' && \
        cat /etc/mkinitcpio.conf | grep '^HOOKS=.*' && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}