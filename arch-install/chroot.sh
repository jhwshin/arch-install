set_locale() {
    echo ">> Setting Locale..."

    for locale in ${LOCALE_GEN[@]}; do
        sed -i "s/^#${locale}/${locale}/" /etc/locale.gen
    done

    locale-gen

    echo "LANG=${LOCALE_SYSTEM}" > /etc/locale.conf

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/locale.conf | grep "${LOCALE_SYSTEM}" && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_timezone() {
    echo ">> Setting Timezone..."

    # symlink timezone
    ln -sfv "/usr/share/zoneinfo/${TIMEZONE_REGION}/${TIMEZONE_CITY}" /etc/localtime

    # sync hardware clock
    hwclock --systohc -v

    # verify
    "${INTERACTIVE_MODE}" && \
        ls -l /etc/localtime && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_hosts() {
    echo ">> Setting up hosts..."

    echo "${HOSTS_CONF}" > /etc/hosts

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/hosts && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_hostname() {
    echo ">> Setting up hostname..."

    echo "${HOSTNAME}" > /etc/hostname

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/hostname && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}

set_users() {
    echo ">> Adding users..."

    # add users with zsh as default shell
    useradd -m -G wheel -s /usr/bin/zsh "${USERNAME}"

    # add wheel group to sudoers
    EDITOR="sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/^# //'" visudo

    passwd "${USERNAME}"    # set password for user
    passwd                  # set password for root

    # verify
    "${INTERACTIVE_MODE}" && \
        cat /etc/sudoers && cat /etc/passwd && \
        printf "\nPress Enter to continue...\n\n"; read; clear
}