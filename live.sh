setup_luks() {
    echo ">> Setting up LUKS..."

    # password hash:
    #   - sha512

    # key derivation:
    #   - argon2id
    #   - use true random
    #   - 512 bit keysize
    #   - pbkdf = 1 GB, 4 threads, 2 seconds

    # cipher:
    #   - aes xts mode with 64 bit plain init vector

    cryptsetup luksFormat \
        --hash sha512 \
        --pbkdf argon2id \
        --use-random \
        --key-size 512 \
        --pbkdf-memory 1048576 \
        --pbkdf-parallel 4 \
        --iter-time 2000 \
        --cipher aes-xts-plain64 \
        --type luks2 \
        --label "CRYPTROOT" \
        --verbose \
        "${ROOT_PARTITION}"

    cryptsetup luksOpen \
        --allow-discards \
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

    # format btrfs
    mkfs.btrfs -L ROOT /dev/mapper/crypt

    mount /dev/mapper/crypt /mnt

    btrfs su create /mnt/${COW_ROOT}

    # create subvols for cow
    for subvol in "${COW_NAME[@]}"; do
        btrfs su create /mnt/${subvol}
    done

    # create subvols for nocow
    for subvol in "${NOCOW_NAME[@]}"; do
        btrfs su create /mnt/${subvol}
    done

    # verify
    "${INTERACTIVE_MODE}" && \
        btrfs su list /mnt && \
        printf "\nPress Enter to continue...\n\n"; read; clear


    echo ">> Mounting BTRFS subvols..."

    umount /mnt

    # mount root
    mount -vo ${COW_OPTS},subvol=${COW_ROOT} /dev/mapper/crypt /mnt

    # create dir for btrfsroot
    mkdir -vp /mnt/.btrfsroot

    # mount btrfs root
    mount -vo ${COW_OPTS},subvolid=5               /dev/mapper/crypt   /mnt/.btrfsroot

    # cow subvols
    for i in "${!COW_NAME[@]}"; do
        # make dir
        mkdir -vp /mnt${COW_MNT[$i]}

        # mount
        mount -vo ${COW_OPTS},subvol=${COW_NAME[$i]} /dev/mapper/crypt /mnt${COW_MNT[$i]}
    done
    
    # nocow subvols
    for i in "${!NOCOW_NAME[@]}"; do
        # make dir
        mkdir -vp /mnt${NOCOW_MNT[$i]}

        # mount
        mount -vo ${NOCOW_OPTS},subvol=${NOCOW_NAME[$i]} /dev/mapper/crypt /mnt${NOCOW_MNT[$i]}

        # set no cow
        chattr +C /mnt${NOCOW_MNT[$i]}
    done

    # mount boot
    mkdir -vp /mnt/boot
    mount "${EFI_PARTITION}" /mnt/boot

    # verify
    "${INTERACTIVE_MODE}" && \
        findmnt -a | grep /mnt && \
        printf "\nPress Enter to continue...\n\n"; read; clear


    echo ">> Setting up SWAP file..."

    # create swapfile in swap subvol
    mkdir -vp /mnt${SWAP_MNT}
    mount -vo ${NOCOW_MNT_OPTS},subvol=${SWAP_NAME} /dev/mapper/crypt /mnt${SWAP_MNT}
    chattr -V +C /mnt${SWAP_MNT}
    btrfs fi mkswapfile --size "${SWAPFILE_SIZE}" /mnt${SWAP_MNT}/swapfile
    swapon /mnt${SWAP_MNT}/swapfile

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
    # subvolid is redundant
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