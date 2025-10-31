#!/usr/bin/env bash

SCRIPT_NAME=$(basename $0)
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/live.sh"
source "${SCRIPT_DIR}/chroot.sh"
source "${SCRIPT_DIR}/hooks.sh"

main() {
    if [[ $# -eq 0 ]]; then
        echo "******** Starting Arch Install... ********"

        if [[ -z ${ROOT_PARTITION} ]]; then
            echo ">> ROOT_PARTITION in env.sh must not be empty! EXITING..."
            exit
        fi

        # pre-chroot
        setup_luks
        setup_btrfs
        update_mirrorlist
        install_arch_base

        # start chroot
        cp -rv "${SCRIPT_DIR}" /mnt/home
        arch-chroot /mnt sh "/home/arch-install/${SCRIPT_NAME}" --chroot

        # post-chroot
        setup_refind_entries_theme

        # clean up
        rm -rv "/mnt/home/arch-install"

        echo "******** Arch Install Completed! ********"
    elif [[ ${1} == "--chroot" ]]; then
        echo ">> Starting chroot..."

        # set basic configuration
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
        install_bootloader
        install_desktop_environments
        install_basic_packages
        install_aur_packages

        misc_configs
        build_initramfs

        echo ">> Finished chroot!"
    fi
}

main $@