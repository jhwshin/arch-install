set_locale() {
    echo ">> Setting Locale..."

    for locale in ${LOCALE_GEN[@]}; do
        sed -i "s/^#${locale}/${locale}/" /etc/locale.gen
    done

    locale-gen

    echo "LANG=${LOCALE_SYSTEM}" > /etc/locale.conf
    echo "${VCONSOLE_CONF}" > /etc/vconsole.conf

    verify "localectl list-locales"
}

set_timezone() {
    echo ">> Setting Timezone..."

    # symlink timezone
    ln -sfv "/usr/share/zoneinfo/${TIMEZONE_REGION}/${TIMEZONE_CITY}" /etc/localtime

    # sync hardware clock
    hwclock --systohc -v

    verify "ls -l /etc/localtime"
}

set_hosts() {
    echo ">> Setting up hosts..."

    echo "${HOSTS_CONF}" > /etc/hosts

    verify "cat /etc/hosts"
}

set_hostname() {
    echo ">> Setting up hostname..."

    echo "${HOSTNAME}" > /etc/hostname

    verify "cat /etc/hostname"
}

set_users() {
    echo ">> Adding users..."

    # add users with zsh as default shell
    useradd -m -G wheel -s /usr/bin/zsh ${USERNAME}

    # add wheel group to sudoers
    EDITOR="sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/^# //'" visudo

    passwd ${USERNAME}      # set password for user
    passwd                  # set password for root

    verify "cat /etc/sudoers && cat /etc/passwd"
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
    verify "cat /etc/pacman.conf | grep "# Misc options" -A 6 &&
            cat /etc/pacman.conf | grep "\[multilib\]" -A 1"
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

    verify ""
}

install_display_servers() {
    echo ">> Installing Display Server..."

    pacman -S ${XORG_PACKAGES[*]} --noconfirm

    verify ""
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

                # enable power saving
                systemctl enable nvidia-suspend
                systemctl enable nvidia-hibernate

                # early KMS will break hibernation with this enabled
                # systemctl enable nvidia-resume
            ;;
        esac
    done

    verify ""
}

install_desktop_environments() {
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
    
    verify "cat /home/${USERNAME}/.xinitrc"
}

install_basic_packages() {
    echo ">> Installing Basic Packages..."

    pacman -S ${ADDITIONAL_PACKAGES[*]} --noconfirm

    verify ""
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

    verify ""
}

install_bootloader() {
    echo ">> Installing Bootloader..."

    CRYPT_UUID="$(lsblk -o NAME,UUID | grep ${ROOT_PARTITION#/dev/} | awk '{print $2}')"
    RESUME_OFFSET="$(btrfs inspect-internal map-swapfile -r /mnt/.swapvol/swapfile)"

    if [[ ${GPU[@]} =~ "nvidia" ]]; then
        # check if modeset worked:
        # $ cat /sys/module/nvidia_drm/parameters
        NVIDIA_KMS_PARAMETERS=""
    fi

    case ${BOOTLOADER} in
        "refind")
            echo ">> Installing rEFIND Bootloader..."

            pacman -S refind --noconfirm

            refind-install

            verify "cat /boot/EFI/refind/refind.conf"
        ;;
    esac
}

misc_configs() {
    echo ">> Setting iwd as Backend..."
    echo "${NETWORK_MANAGER_CONFIG}" > "/etc/NetworkManager/conf.d/wifi_backend.conf"

    echo ">> Setting up Reflector..."
    mkdir -p /etc/xdg/reflector
    echo "${REFLECTOR_CONFIG}" > "/etc/xdg/reflector/reflector.conf"

    echo ">> Pruning .snapshots in /etc/updatedb.conf..."
    # prevent snapshot slowdowns
    echo 'PRUNENAMES = ".snapshots"' >> /etc/updatedb.conf

}

pacman_hooks() {
    echo ">> Setting up Systemd Hooks..."

    HOOKS_DIR="/etc/pacman.d/hooks"
    mkdir -p ${HOOKS_DIR}

    # required for secureboot
    echo "${MOKS_HOOK}" > "${HOOKS_DIR}/999-sign_kernel_for_secureboot.hook"
    echo "${REFIND_HOOK}" > "${HOOKS_DIR}/refind.hook"

    # refresh zsh
    echo "${ZSH_HOOK}" > "${HOOKS_DIR}/zsh.hook"

    verify "ls -l ${HOOKS_DIR}"
}

systemd_units() {
    echo ">> Enabling Systemd Startups..."

    systemctl enable ${SYSTEMD_STARTUPS[*]}

    verify ""
}

build_initramfs() {
    echo ">> Rebuilding Initramfs..."

    # replace MODULES array
    sed -i "s/^MODULES=.*/MODULES=( ${MODULES[*]} )/" /etc/mkinitcpio.conf

    # replace HOOKS array
    sed -i "s/^HOOKS=.*/HOOKS=( ${HOOKS[*]} )/" /etc/mkinitcpio.conf

    # rebuild initramfs
    mkinitcpio -P

    # verify modules and hooks
    verify "cat /etc/mkinitcpio.conf | grep '^MODULES=.*' && \
            cat /etc/mkinitcpio.conf | grep '^HOOKS=.*' &&"
}