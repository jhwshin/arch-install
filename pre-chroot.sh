setup_luks() {
    echo ">> Setting up LUKS..."

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
        --label "CRYPT_ROOT" \
        --verbose \
        "${ROOT_PARTITION}"

    cryptsetup luksOpen \
        --allow-discards \
        --persistent \
        --verbose \
        "${ROOT_PARTITION}" crypt

    verify "cryptsetup luksDump ${ROOT_PARTITION}"
}

setup_btrfs() {
    echo ">> Setting up BTRFS..."

    MOUNT_OPTS="noatime,nodiratime,compress=zstd:3"
    NOCOW_MOUNT_OPTS="compress=no"

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
    btrfs su create /mnt/@nocow

    verify "btrfs su list /mnt"

    umount /mnt

    echo ">> Mounting BTRFS subvols..."

    mount -vo ${MOUNT_OPTS},subvol=@ /dev/mapper/crypt /mnt

    mkdir -vp /mnt/{home,home/${USERNAME}/.nocow,.snapshots,tmp,.swapvol,.btrfsroot}
    mkdir -vp /mnt/var/{log,cache,tmp,lib/docker,lib/libvirt/images}

    mount -vo ${MOUNT_OPTS},subvol=@home             /dev/mapper/crypt   /mnt/home
    mount -vo ${MOUNT_OPTS},subvol=@snapshots        /dev/mapper/crypt   /mnt/.snapshots

    mount -vo ${MOUNT_OPTS},subvolid=5               /dev/mapper/crypt   /mnt/.btrfsroot

    mount -vo ${MOUNT_OPTS},subvol=@var_log          /dev/mapper/crypt   /mnt/var/log
    mount -vo ${MOUNT_OPTS},subvol=@var_cache        /dev/mapper/crypt   /mnt/var/cache
    mount -vo ${MOUNT_OPTS},subvol=@var_tmp          /dev/mapper/crypt   /mnt/var/tmp
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@docker     /dev/mapper/crypt   /mnt/var/lib/docker
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@libvirt    /dev/mapper/crypt   /mnt/var/lib/libvirt/images
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@swap       /dev/mapper/crypt   /mnt/.swapvol
    mount -vo ${NOCOW_MOUNT_OPTS},subvol=@nocow      /dev/mapper/crypt   /mnt/home/${USERNAME}/.nocow

    chattr +C /mnt/tmp
    chattr +C /mnt/var/log
    chattr +C /mnt/var/cache
    chattr +C /mnt/var/tmp
    chattr +C /mnt/var/lib/docker
    chattr +C /mnt/var/lib/libvirt/images
    chattr +C /mnt/.swapvol
    chattr +C /mnt/home/${USERNAME}/.nocow

    mkdir -vp /mnt/boot
    mount "${EFI_PARTITION}" /mnt/boot

    verify "findmnt -a | grep /mnt"

    echo ">> Setting up SWAP file..."

    btrfs fi mkswapfile --size "${SWAPFILE_SIZE}" /mnt/.swapvol/swapfile
    swapon /mnt/.swapvol/swapfile

    verify "swapon -a"
}

update_mirrorlist() {
    echo ">> Updating mirrors..."

    # backup mirrorlist incase
    cp -v /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

    # find fastest mirrors
    reflector \
        --country "${MIRROR_REGIONS}" \
        --verbose --latest 10 \
        --number 10 \
        --sort rate \
        --save /etc/pacman.d/mirrorlist

    verify "cat /etc/pacman.d/mirrorlist"
}

install_arch_base() {
    echo ">> Installing Arch Base..."

    pacstrap /mnt/ ${BASE_PACKAGES[*]} --noconfirm

    # generate fstab
    genfstab -U /mnt > /mnt/etc/fstab

    verify "cat /mnt/etc/fstab"
}