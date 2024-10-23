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