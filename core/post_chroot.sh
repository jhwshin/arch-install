#!/usr/bin/env bash

refind_setup() {
    echo ">> Setting up rEFIND Theme and Entries..."

    git clone https://github.com/jhwshin/refind-dreary /mnt/boot/EFI/refind/refind-dreary
    sh /mnt/boot/EFI/refind/refind-dreary/install.sh lowres /mnt/boot/EFI/refind
    rm -rf /mnt/boot/EFI/refind/refind-dreary

    UUID="$(lsblk -o NAME,UUID | grep ${ROOT_PARTITION#/dev/} | awk '{print $2}')"
    RESUME_OFFSET="$(btrfs inspect-internal map-swapfile -r /mnt/.swapvol/swapfile)"

    cat << EOF >> /mnt/boot/EFI/refind/refind.conf

timeout 10
log_level 0
default_selection +
resolution max

# enable_touch
# enable mouse
# scan_delay 1
# scanfor manual, external, internal
# use_graphics_for +, linux

# banner, label, arrows, editor
hide singlueuser, hints, badges

# shell, memtest
showtools mok_tool, hidden_tags, reboot, shutdown, firmware

menuentry "Windows 11" {
    icon        /EFI/refind/themes/refind-dreary/icons/os_win.png
    volume      Windows
    loader      \EFI\Microsoft\Boot\bootmgfw.efi
}

menuentry "Arch Linux" {
    icon        /EFI/refind/themes/refind-dreary/icons/os_arch.png
    volume      "CRYPTROOT"
    loader      \vmlinuz-linux
    initrd      \initramfs-linux.img
    options     "rd.luks.name=${UUID}=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ resume=/dev/mapper/cryptroot resume_offset=${RESUME_OFFSET} rw ${KERNEL_PARAMS}"
    #options    "root=UUID=${UUID} resume=/dev/mapper/cryptroot resume_offset=${RESUME_OFFSET} rw ${KERNEL_PARAMS}"

    submenuentry "Zen" {
        loader  \vmlinuz-linux-zen
        initrd  \initramfs-linux-zen.img
    }

    submenuentry "LTS" {
        loader  \vmlinuz-linux-lts
        initrd  \initramfs-linux-lts.img
    }

    submenuentry "Linux - Fallback" {
        initrd  \initramfs-linux-fallback.img
    }

    submenuentry "Zen - Fallback" {
        loader  \vmlinuz-linux-zen
        initrd  \initramfs-linux-zen-fallback.img
    }

    submenuentry "LTS - Fallback" {
        loader  \vmlinuz-linux-lts
        initrd  \initramfs-linux-lts-fallback.img
    }

    submenuentry "Multi User (no GUI)" {
        add_options "systemd.unit=multi-user.target"
    }

    submenuentry "Single User (Recovery)" {
        add_options "systemd.unit=rescue.target"
    }

    submenuentry "Initramfs (Emergency)" {
        add_options "systemd.unit=emergency.target loglevel=4 systemd.log_level=debug"
    }

    #submenuentry "UEFI (Terminal)" {
    #    loader \EFI\tools\Shellx64.efi
    #    initrd
    #    options
    #}
}
EOF
}