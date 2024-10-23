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