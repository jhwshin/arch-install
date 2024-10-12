SCRIPT_NAME=$(basename "${0}")
SCRIPT_PATH=$(realpath "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/chroot.sh"
source "${SCRIPT_DIR}/pre-chroot.sh"
source "${SCRIPT_DIR}/hooks.sh"

main() {
    if [[ $# -eq 0 ]]; then
        echo "******** Starting Arch Install... ********"

        # setup partitions and filesystem
        # before anything, for safety ROOT_PARTITION must be specified
        if [[ -z {ROOT_PARTITION} ]]; then
            echo ">> ROOT_PARTITION must be specified in config! EXITING..."
            exit
        fi
        
        setup_luks
        setup_btrfs

        # install pacstrap
        update_mirrorlist
        install_arch_base

        # copy script over to /mnt so we can chroot
        cp -rv "${SCRIPT_DIR}" /mnt/home
        arch-chroot /mnt sh "/home/arch-install/${SCRIPT_NAME}" --chroot

        #refind?

        # clean up install script files
        rm -r "/mnt/home/arch-install/"

        exit

        echo "******** Arch Install Completed! ********"
    fi

    elif [[ ${1} == "--chroot" ]]; then
        echo ">> Starting chroot..."

        # set basic configurations
        set_locale
        set_timezone
        set_hosts
        set_hostname
        set_users
        edit_pacman_conf

        # install packages
        install_cpu_microcode
        install_display_servers
        install_gpu_drivers
        install_desktop_environments
        install_basic_packages
        install_aur
        install_bootloader

        # misc settings
        misc_configs
        pacman_hooks
        systemd_units

        # rebuild initramfs
        build_initramfs

        echo ">> Finished chroot!"
    fi
}

main $@