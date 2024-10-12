# arch-install

A simple Arch Linux installer script written for myself.

I highly recommend you don't run this script as they may not suit your needs or your system, but rather use it as a reference or a guide.

If you are unfamiliar with the arch install process then definitely don't run this script without carefully reading through the it.

And as always, back up your system first!!

## Summary

<details>
    <summary>What does this script include?</summary>
</details>

<details>
<summary>How does it work?</summary>

Basically condensed everything to a single file for simiplicity and portability.

Setup the partition as per your needs and edit the variables in the config.

You only need to run the script first which will execute the __'pre-chroot'__ part. 

The script will then copy over itself to `/mnt` and `chroot` into it, and then finally run the __'chroot'__ part of the script. It will also clean itself up by removing the copied script in `/mnt` after the installation is complete.
</details>

- Dual Boot Compatible - `Windows` + `Linux`
- Filesystem - `BTRFS` on `LUKS`
- SWAP File + Hibernation
- Bootloader - `rEFIND`
- Secure Boot - `shim-signed` + `sbsigntools` (MOKS)
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
- Configs
 - Locale - `/etc/locale.gen` + `/etc/local.conf`
 - Timezone - `/etc/localtime`
 - Hosts - `/etc/hosts`
 - Hostname - `/etc/hostname`
 - Users + Sudoers
 - Pacman + 32-bit Mirrors - `/etc/pacman.conf`
 - Reflector Mirrors - `/etc/reflector`
- PACMAN HOOKS
 - `nvidia` - driver updates
 - `shim` - secure boot sign
 - `sbsigntools` - secure boot sign
 - `zsh` - refresh cache

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

# setup root partition and EFI (if not dual booting)
# install script will create luks and btrfs
$ fdisk /dev/<sdX>

# if not dual booting
# $ mkfs.vfat -F -n "EFI" /dev/<sdXY>
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
$ pacman -S git glibc # required for git
```

6. Clone repo:
```bash
$ git clone https://github.com/jhwshin/arch-install.git
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

---

- Partition Table - `MBR` or `GPT`
- Filesystem - `ext4` on `lvm`
- Bootloader - `grub`
