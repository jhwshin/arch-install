# arch-install

A simple Arch Linux installer script written for myself.

I highly recommend you don't run this script as they may not suit your needs or your system, but rather use it as a reference or a guide.

If you are unfamiliar with the arch install process then definitely don't run this script without carefully reading through the it.

And as always, back up your system first!!

## Summary

<details>
    <summary>What does this script include?</summary>

- Dual Boot Compatible - `Windows` (install first) + `Linux`
- File System - `BTRFS` (CoW FS) on `LUKS` (Encryption)
- SWAP File + Hibernation
- Bootloader - `rEFIND` (Mouse + Touchscreen Functional)
- Secure Boot - `shim-signed` + `sbsigntools` (MOK Signed)
- Kernel - `linux` + `linux-lts` + `linux-zen`
- Drivers
    - CPU - `intel` (microcode)
    - GPU - `intel` (igpu) + `nvidia-dkms`
- Display Server - `X11`
- Desktop Environment - `i3` + `xfce` + `gnome`
- Applications
    - Audio - `alsa` + `pavucontrol`
    - Bluetooth - `blueman`
    - Network - `NetworkManager` + `iwd` (Backend)
    - AUR - `yay`
    - Other additional packages...
- Configs
    - Locale - `/etc/locale.gen` + `/etc/local.conf`
    - Timezone - `/etc/localtime`
    - Hosts - `/etc/hosts`
    - Hostname - `/etc/hostname`
    - Users + Sudoers
    - Pacman + 32-bit Mirrors - `/etc/pacman.conf`
    - Reflector Mirrors - `/etc/reflector`
- HOOKS
    - `shim` + `sbsigntools` - secure boot sign
    - `nvidia` - rebuild with kernel or nvidia driver updates
    - `zsh` - refresh cache
</details>

<details>
<summary>How does it work?</summary>

Basically condensed everything to a single file for simiplicity and portability.

Setup the partition as per your needs and edit the variables in the config.

You only need to run the script first which will execute the __'pre-chroot'__ part. 

The script will then copy over itself to `/mnt` and `chroot` into it, and then finally run the __'chroot'__ part of the script. It will also clean itself up by removing the copied script in `/mnt` after the installation is complete.

</details>

## Instructions

1. Verify system is running on EFI:
```bash
# if directory is populated system is EFI
$ ls /sys/firmware/efi/efivars

# remove residual NVRAM entries from past installs if required
$ rm -rf /sys/firmware/efi/efivars/Boot*
```

2. Sync hardware clock:
```bash
# sync system clock with network time
$ timedatectl set-ntp true
```

3. List partition table:
```bash
# quick disk list
$ lsblk

# verbose disk list
$ fdisk -l

# if not dualbooting create partition table
#   and setup partitions to your needs
#   then finally make sure to add the ROOT_PARTITION (linux) and EFI_PARTITION to config
# GPT (EFI) or MBR (BIOS)
$ fdisk /dev/<sdX>
```

4. Connect to WiFi:
```bash
$ iwctl

# get network adapter
[iwd]# device list

# scan wifi networks
[iwd]# station <DEVICE> scan

# list wifi networks
[iwd]# station <DEVICE> get-networks

# connect to wifi network
[iwd]# station <DEVICE> connect <SSID>

# check connection
$ ping 8.8.8.8
```

5. Install git:
```bash
$ pacman -Syy
$ pacman -S git glibc
```

6. Clone repo:
```bash
$ git clone https://github.com/jhwshin/arch-install.git
```

7. Verify and edit installer configs - __!! IMPORTANT !!__
```bash
$ cd arch-install
$ nano arch-install.sh
```

8. Run installer:
```bash
$ bash arch-install.sh
```

9. Finshing up:
```bash
# if you want to make more changes or verify the installed system
# $ arch-chroot /mnt

# otherwise just umount and restart the system
$ umount -R /mnt
$ reboot
```

10. After reboot setup secure boot if required:
```bash
# install secure boot tools
$ yay -S shim-signed sbsigntools

# trigger hooks by reinstalling package
$ yay -S refind linux
```