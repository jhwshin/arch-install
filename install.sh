#!/usr/bin/env bash

SCRIPT_NAME=$(basename $0)
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_DIR}/settings.sh"
source "${SCRIPT_DIR}/core/utils.sh"
source "${SCRIPT_DIR}/core/pre_chroot.sh"
source "${SCRIPT_DIR}/core/chroot.sh"
source "${SCRIPT_DIR}/core/post_chroot.sh"

main() {
    if [[ $# -eq 0 ]]; then
        echo "******** Starting Arch Install... ********"

        if [[ -z "${ROOT_PARTITION}" || -z "${BOOT_PARTITION}" ]]; then
            echo ">> PARTITION VARIABLE in settings.sh must NOT be empty! EXITING..."
            exit
        fi

        # pre-chroot
        echo ">> Starting pre-chroot Setup..."
        setup_luks
        setup_btrfs
        update_mirrorlist
        install_arch_base
        genfstab -U /mnt > /mnt/etc/fstab
        fix_fstab_btrfs_entries

        # chroot
        cp -r "${SCRIPT_DIR}" /mnt/home/
        arch-chroot /mnt bash "/home/arch-install/install.sh" --chroot

        # post-chroot
        echo ">> Starting post-chroot Setup..."
        refind_setup

        # clean up
        rm -rf "/mnt/home/arch-install"

        echo "******** Arch Install Complete! ********"

    elif [[ ${1} == "--chroot" ]]; then
        echo ">> Entering chroot..."

        # set basic configuration
        set_locale
        set_timezone
        set_hosts
        set_hostname
        set_users
        modify_pacman_conf

        # install packages
        install_cpu_microcode
        install_gpu_drivers
        install_display_servers
        install_bootloader
        install_desktop_environments
        install_basic_packages
        install_aur_packages

        # misc setup
        enable_systemd_services
        #setup_snapper # broken
        misc_configs
        # [[ "${BOOTLOADER}" == "refind" ]] && setup_refind_secureboot # broken
        build_initramfs

        echo ">> Finished chroot!"
    fi
}

main $@