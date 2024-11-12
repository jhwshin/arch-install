# arch-install

A simple Arch Linux installer script written for myself.

I highly recommend you don't run this script as they may not suit your needs or your system, but rather use it as a reference or a guide.

If you are unfamiliar with the arch install process then definitely don't run this script without carefully reading through the it.

And as always, back up your system first!!

<details>
    <summary>What does this script include?</summary>

- Dual Boot Compatible - `Windows` + `Linux`
- Filesystem - `BTRFS` (CoW FS) on `LUKS` (Encryption)
- SWAP File + Hibernation
- Bootloader - `rEFIND` + `refind-dreary` theme
- Secure Boot - `shim-signed` + `sbsigntools` (using MOKS)
- Kernel - `linux` + `linux-lts` + `linux-zen`
- Drivers
    - CPU - `intel`
    - GPU - `intel` + `nvidia-dkms`
- Display Server - `X11`
- Desktop Environment - `i3` + `xfce` + `gnome`
- Applications
    - Audio - `alsa` + `pulseaudio` + `pavucontrol`
    - Bluetooth - `bluez` + `blueman`
    - Network - `NetworkManager` + `iwd`
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

</details>

<details>
<summary>How does it work?</summary>

Setup filesystem as per your needs.
By default it wont create EFI (assumes dual boot on same drive)
Setup BTRFS on LUKS

Edit variable in `env.sh` and hooks in `hooks.sh`
Functions outside of chroot are located in `live.sh`
Whilst functions in chroot are located in `chroot.sh`

When you run `install.sh` it will source from all those files above and execute them accordingly.

After prechroot (live) part, the script will then copy over itself to `/mnt` and `chroot` into it, and then finally run the `chroot.sh` functions.
It will also clean itself up by removing the copied script in `/mnt` after the installation is complete.

</details>

## Update Notes

- nvidia 565.x and 560.x [FAIL]
  - fails with luks password prompt
- nvidia 555.x [WORKING]
  - early kms modules fail (don't add them in mkinitcpio)
  - enable nvidia-{hibernate,suspend} __NOT__ nvidia-resume

## Instructions

1. Verify system is running on EFI:
```bash
# if directory is populated system is EFI
$ ls /sys/firmware/efi/efivars

# remove residual NVRAM entries from past installs if required
# $ rm -rf /sys/firmware/efi/efivars/Boot*
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

# setup gpt, root partition and EFI (if not dual booting)
# install script will create luks and btrfs
$ fdisk /dev/<sdX>

# if not dual booting
# $ mkfs.vfat -F32 -n "EFI" /dev/<sdXY>
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
$ pacman -S git glibc       # required for git
```

6. Clone repo:
```bash
$ git clone https://github.com/jhwshin/arch-install
```

7. Verify and edit installer configs - __!! IMPORTANT !!__
```bash
$ cd arch-install
$ nano env.sh
```

8. Run installer:
```bash
$ bash install.sh
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

# create rEFIND keys and cert
$ refind-install --shim /usr/share/shim-signed/shimx64.efi --localkeys

# trigger hooks by reinstalling package
$ yay -S refind linux

# finally sign bootloader with MOKs at boot located in
# /boot/EFI/refind/keys/*.crt
```

## Extras

rEFIND Theme - [refind-dreary fork](https://www.github.com/jhwshin/refind-dreary.git)

dotfiles - [jhwshin dotfiles](https://www.github.com/jhwshin/.dotfiles.git)


---

TODO:

 - Partition Table opts - `MBR`
 - Filesystem opts - `ext4` and `lvm`
 - Bootloader opts - `grub`