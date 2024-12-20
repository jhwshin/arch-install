setup_luks() {
    echo ">> Setting up LUKS..."

    # key derivation:
    #   - sha512
    #   - argon2id
    #   - real random
    #   - 512 bit keysize
    #   - 1 GB, 4 threads, 2 seconds = pbkdf
    # cipher:
    #   - aes xts mode with 64 bit plain init vector
    #   - disable rw work queue (lower latency, higher cpu)

    cryptsetup luksFormat \
        --hash sha512 \
        --pbkdf argon2id \
        --use-random \
        --key-size 512 \
        --pbkdf-memory 1048576 \
        --pbkdf-parallel 4 \
        --iter-time 2000 \
        --cipher aes-xts-plain64 \
        --perf-no_read_workqueue \
        --perf-no_write_workqueue \
        --type luks2 \
        --label "CRYPTROOT" \
        --verbose \
        "${ROOT_PARTITION}"

    cryptsetup luksOpen \
        --allow-discards \
        --perf-no_read_workqueue \
        --perf-no_write_workqueue \
        --persistent \
        --verbose \
        "${ROOT_PARTITION}" crypt

    # verify
    "${INTERACTIVE_MODE}" && \
        cryptsetup luksDump "${ROOT_PARTITION}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

setup_btrfs() {
    echo ">> Setting up BTRFS..."

    MOUNT_OPTS="noatime,nodiratime,compress=zstd:3"
    NOCOW_MOUNT_OPTS="noatime,nodiratime,compress=no"

    # format btrfs
    mkfs.btrfs -L ROOT /dev/mapper/crypt

    mount /dev/mapper/crypt /mnt

    # create subvols
    btrfs su create /mnt/@
    btrfs su create /mnt/@home
    btrfs su create /mnt/@snapshots

    # create nocow subvols
    btrfs su create /mnt/@var_log
    btrfs su create /mnt/@var_cache
    btrfs su create /mnt/@var_tmp
    btrfs su create /mnt/@docker
    btrfs su create /mnt/@libvirt
    btrfs su create /mnt/@swap

    # verify
    "${INTERACTIVE_MODE}" && \
        btrfs su list /mnt && \
        printf "\nPress Enter to continue...\n\n"; read; clear


    echo ">> Mounting BTRFS subvols..."

    umount /mnt

    # mount root
    mount -vo ${MOUNT_OPTS},subvol=@ /dev/mapper/crypt /mnt

    # make subvols
    mkdir -vp /mnt/{home,.snapshots,.swapvol,.btrfsroot}
    mkdir -vp /mnt/var/{log,cache,tmp,lib/docker,lib/libvirt/images}

    # mount btrfs root
    mount -vo ${MOUNT_OPTS},subvolid=5               /dev/mapper/crypt   /mnt/.btrfsroot

    # mount subvols
    mount -vo ${MOUNT_OPTS},subvol=@home            /dev/mapper/crypt   /mnt/home
    mount -vo ${MOUNT_OPTS},subvol=@snapshots       /dev/mapper/crypt   /mnt/.snapshots

    # mount nocow subvols
    mount -vo ${MOUNT_OPTS},subvol=@var_log          /dev/mapper/crypt   /mnt/var/log
    mount -vo ${MOUNT_OPTS},subvol=@var_cache        /dev/mapper/crypt   /mnt/var/cache
    mount -vo ${MOUNT_OPTS},subvol=@var_tmp          /dev/mapper/crypt   /mnt/var/tmp
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@docker     /dev/mapper/crypt   /mnt/var/lib/docker
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@libvirt    /dev/mapper/crypt   /mnt/var/lib/libvirt/images
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@swap       /dev/mapper/crypt   /mnt/.swapvol

    # set nocow
    chattr +C /mnt/var/log
    chattr +C /mnt/var/cache
    chattr +C /mnt/var/tmp
    chattr +C /mnt/var/lib/docker
    chattr +C /mnt/var/lib/libvirt/images
    chattr +C /mnt/.swapvol

    # mount boot
    mkdir -vp /mnt/boot
    mount "${EFI_PARTITION}" /mnt/boot

    # verify
    "${INTERACTIVE_MODE}" && \
        findmnt -a | grep /mnt && \
        printf "\nPress Enter to continue...\n\n"; read; clear


    echo ">> Setting up SWAP file..."

    # create swapfile in swap subvol
    btrfs fi mkswapfile --size "${SWAPFILE_SIZE}" /mnt/.swapvol/swapfile
    swapon /mnt/.swapvol/swapfile

    # verify
    "${INTERACTIVE_MODE}" && \
        swapon -a && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

update_mirrorlist() {
    echo ">> Updating mirrors..."

    # backup mirrorlist incase
    cp -v /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

    # find fastest mirrors
    reflector \
        --country "${MIRROR_REGIONS}" \
        --verbose \
        --latest 10 \
        --number 10 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/pacman.d/mirrorlist && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

install_arch_base() {
    echo ">> Installing Arch Base..."

    pacstrap /mnt/ ${BASE_PACKAGES[*]} --noconfirm

    # generate fstab
    genfstab -U /mnt > /mnt/etc/fstab

    # quick dirty fix to fstab
    # remove subvolid from all (except btrfsroot where subvolid=5)
    sed -i 's/subvolid=[0-46-9][0-9]*,//g' /mnt/etc/fstab

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /mnt/etc/fstab && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

setup_refind_entries_theme() {
    echo ">> Installing Arch Base..."

    CRYPT_UUID="$(lsblk -o NAME,UUID | grep ${ROOT_PARTITION#/dev/} | awk '{print $2}')"
    RESUME_OFFSET="$(btrfs inspect-internal map-swapfile -r /mnt/.swapvol/swapfile)"

    if [[ "${GPU[@]}" =~ 'nvidia' ]]; then
        NVIDIA_KERNEL_PARAMS=true
    fi

    git clone https://github.com/jhwshin/refind-dreary /mnt/boot/EFI/refind/refind-dreary
    sh /mnt/boot/EFI/refind/refind-dreary/install.sh lowres /mnt/boot/EFI/refind ${CRYPT_UUID} ${RESUME_OFFSET} ${NVIDIA_KERNEL_PARAMS}
    rm -rf /mnt/boot/EFI/refind/refind-dreary

    # verify
    "${INTERACTIVE_MODE}" && \
        tail -n 70 /mnt/boot/EFI/refind/refind.conf && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}