# ------------------------------------------------
#   PACMAN HOOKS
# ------------------------------------------------

NVIDIA_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=nvidia-lts
Target=nvidia-dkms
Target=nvidia-utils
Target=lib32-nvidia-utils
Target=linux
Target=linux-lts
Target=linux-hardened
Target=linux-zen

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'"

# secure boot hooks
MOKS_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=linux
Target=linux-lts
Target=linux-hardened
Target=linux-zen
Target=linux-surface

[Action]
Description=Signing kernel with Machine Owner Key for Secure Boot
When=PostTransaction
Exec=/usr/bin/find /boot/ -maxdepth 1 -name 'vmlinuz-*' -exec /usr/bin/sh -c 'if ! /usr/bin/sbverify --list {} 2>/dev/null | /usr/bin/grep -q \"signature certificates\"; then /usr/bin/sbsign --key /etc/refind.d/keys/refind_local.key --cert /etc/refind.d/keys/refind_local.crt --output {} {}; fi' ;
Depends=sbsigntools
Depends=findutils
Depends=grep"

REFIND_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=refind

[Action]
Description=Updating rEFInd on ESP
When=PostTransaction
Exec=/usr/bin/refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys"

ZSH_HOOK="[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Path
Target=usr/bin/*

[Action]
Depends=zsh
When=PostTransaction
Exec=/usr/bin/install -Dm644 /dev/null /var/cache/zsh/pacman"