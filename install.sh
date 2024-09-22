
SCRIPT_NAME=$(basename "${0}")
SCRIPT_PATH=$(realpath "${0}")
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/chroot.sh"
source "${SCRIPT_DIR}/pre-chroot.sh"

refind_entries() {
    CRYPT_UUID="$(lsblk -o NAME,UUID | grep ${ROOT_PARTITION#/dev/} | awk '{print $2}')"
    RESUME_OFFSET="$(btrfs inspect-internal map-swapfile -r /mnt/.swapvol/swapfile)"

    if [[ ! ${GPU[@]} =~ "nvidia" ]]; then
        # check if modeset worked:
        # $ cat /sys/module/nvidia_drm/parameters
        NVIDIA_KERNEL_PARAMS=""
    fi

    cat >> /mnt/boot/EFI/refind/refind.conf << EOF
# Global Settings
timeout 10                          #   [-1, 0, 0+] (skip, no timeout, x seconds)
log_level 0                         #   [0-4]
#enable_touch
#enable_mouse
#dont_scan_volumes "<LABEL>"        #   Prevent duplicate non-custom Linux entries using <LABEL> use e2label to label partition
                                    #   or for LUKS cryptsetup config /dev/<sdXY> --label <LABEL>
default_selection +                 #   Microsoft, Arch, + (most recently boot)
resolution max

# UI Settings
# hideui banner, label, singleuser, arrows, hints, editor, badges
hideui singleuser, hints, badges
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
EOF
}

main() {

    if [[ $# -eq 0 ]]; then
        echo "******** Starting Arch Install... ********"

        # setup partitions and filesystem
        setup_luks
        setup_btrfs

        # install pacstrap
        update_mirrorlist
        install_arch_base

        # copy script over to /mnt so we can chroot
        cp -rv "${SCRIPT_DIR}" /mnt/home
        arch-chroot /mnt sh "/home/arch-install/${SCRIPT_NAME}" --chroot

        # add refind entries (doesn't work in chroot)
        refind_entries

        # clean up install script files
        rm "/mnt/home/arch-install/${SCRIPT_NAME}"

        exit

        echo "******** Arch Install Completed! ********"

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
