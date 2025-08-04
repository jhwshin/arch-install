#!/usr/bin/env bash

setup_luks() {
    echo ">> Setting up [LUKS] Encryption..."

    # create encrypted container
    cryptsetup luksFormat \
        --hash sha512 \
        --use-random \
        --pbkdf argon2id \
        --iter-time 4000 \
        --key-size 512 \
        --label "CRYPTROOT" \
        --verbose \
        "${ROOT_PARTITION}"

    # open encrypted container
    cryptsetup luksOpen \
        --allow-discards \
        --persistent \
        --verbose \
        "${ROOT_PARTITION}" \
        "cryptroot"

    "${VERIFY}" && \
        cryptsetup luksDump "${ROOT_PARTITION}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

setup_btrfs() {
    echo ">> Setting up [BTRFS] Filesystem..."

    mkfs.btrfs -L "ROOT" /dev/mapper/cryptroot

    mount /dev/mapper/cryptroot /mnt

    # CoW subvolumes
    btrfs su create /mnt/@
    btrfs su create /mnt/@home
    btrfs su create /mnt/@root
    btrfs su create /mnt/@snapshots
    btrfs su create /mnt/@srv

    # no CoW subvolumes
    btrfs su create /mnt/@var_cache
    btrfs su create /mnt/@var_log
    btrfs su create /mnt/@var_tmp
    btrfs su create /mnt/@docker
    btrfs su create /mnt/@libvirt
    btrfs su create /mnt/@nocow
    btrfs su create /mnt/@swap
    
    umount /mnt

    # mount root first
    mount -vo ${BTRFS_SU_COW_OPTS},subvol=@ /dev/mapper/cryptroot /mnt

    # create directories
    mkdir -vp /mnt/{.btrfsroot,boot,home,root,.snapshots,srv,.nocow,.swapvol,var/{cache,log,tmp,lib/{docker,libvirt/images}}}

    # mount BTRFS root second
    mount -vo ${BTRFS_SU_COW_OPTS},subvolid=5 /dev/mapper/cryptroot /mnt/.btrfsroot

    # mount Cow subvolumes
    mount -vo ${BTRFS_SU_COW_OPTS},subvol=@home /dev/mapper/cryptroot /mnt/home
    mount -vo ${BTRFS_SU_COW_OPTS},subvol=@root /dev/mapper/cryptroot /mnt/root
    mount -vo ${BTRFS_SU_COW_OPTS},subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
    mount -vo ${BTRFS_SU_COW_OPTS},subvol=@srv /dev/mapper/cryptroot /mnt/srv

    # mount no Cow subvolumes
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@var_cache /dev/mapper/cryptroot /mnt/var/cache
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@var_log /dev/mapper/cryptroot /mnt/var/log
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@var_tmp /dev/mapper/cryptroot /mnt/var/tmp
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@docker /dev/mapper/cryptroot /mnt/var/lib/docker
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@libvirt /dev/mapper/cryptroot /mnt/var/lib/libvirt/images
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@nocow /dev/mapper/cryptroot /mnt/.nocow
    mount -vo ${BTRFS_SU_NOCOW_OPTS},subvol=@swap /dev/mapper/cryptroot /mnt/.swapvol

    # mount boot
    mount -v "${BOOT_PARTITION}" /mnt/boot

    # set no CoW
    chattr +C /mnt/{.nocow,.swapvol,var/{cache,log,tmp,lib/{docker,libvirt/images}}}

    # create swapfile
    btrfs fi mkswapfile --size ${SWAPFILE_SIZE} /mnt/.swapvol/swapfile

    # enable swap
    swapon /mnt/.swapvol/swapfile

    # TODO - findmnt and show swap
    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

update_mirrorlist() {
    echo ">> Updating Mirrors..."

    # backup mirrorlist
    cp -v /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

    # find top 10 fastest mirrors
    reflector \
        --country "${MIRROR_REGIONS}" \
        --latest 10 \
        --number 10 \
        --sort rate \
        --verbose \
        --save /etc/pacman.d/mirrorlist

    "${VERIFY}" && \
        tail -v -n +1 /etc/pacman.d/mirrorlist && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

install_arch_base() {
    echo ">> Installing Arch Base Packages..."

    pacstrap /mnt ${ARCH_BASE_PKGS[*]} --noconfirm

    "${VERIFY}" && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}

fix_fstab_btrfs_entries() {
    echo ">> Fixing BTRFS fstab Entries..."

    # TO FIX - commas in variable breaks sed
    #sed -i -E "/@var|@docker|@libvirt|@nocow|@swap/ s/${BTRFS_SU_COW_OPTS}/${BTRFS_SU_NOCOW_OPTS}/g" /mnt/etc/fstab
    #sed -i -E "/btrfsroot/ s/subvol=\/subvolid=5/" /mnt/etc/fstab

    "${VERIFY}" && \
        tail -v -n +1 /mnt/etc/fstab && \
    printf "\n Press [ENTER] to continue...\n\n" && read && clear
}