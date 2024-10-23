SCRIPT_NAME=$(basename $0)
SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname "${SCRIPT_PATH}")

source "${SCRIPT_DIR}/env.sh"
source "${SCRIPT_DIR}/live.sh"

main() {
    if [[ $# -eq 0 ]]; then
        echo "******** Starting Arch Install... ********"

        if [[ ${ROOT_PARTITION} ]]; then
            echo ">> ROOT_PARTITION in env.sh must not be empty! EXITING..."
            exit
        fi

        # pre-chroot
        setup_luks
        setup_btrfs

        # start chroot
        cp -rv "${SCRIPT_DIR}" /mnt/home
        arch-chroot /mnt sh "/home/arch-install/${SCRIPT_NAME}" --chroot

        # post-chroot

        # clean up
        rm -rv "/mnt/home/arch-install"

        echo "******** Arch Install Completed! ********"
    elif
        echo ">> Starting chroot..."

        # ...

        echo ">> Finished chroot!"
    fi
}

main $@