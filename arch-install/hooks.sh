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
