# arch-install

A very basic and minimal automated Arch Linux install script.

Includes:
* arch base linux and lts-linux

* locale
* timezone
* hostname
* hosts
* user
* sudoer
* 32-bit mirrors

* swap and hibernation
* windows dualboot time fix

* cpu microcode
* gpu driver
* bootloader
* desktop environment
* display manager

* audio - `alsa` and `pavucontrol`
* network - `networkmanager`
* bluetooth - `bluez` and `blueman`
* ssh
* xdg
* git
* nano

## Pre-Installation

1. Create bootable Arch USB
2. Setup partition table and partitions
3. Format partitions and mount:
```bash
# mount ROOT partition
mkfs.ext4 /dev/sd<XY>
mount /dev/sd<XY> /mnt

# mount EFI partition (UEFI only)
mkfs.fat -F32 /dev/sd<XZ>           # skip this line if windows boot exists in EFI
mkdir /mnt/boot
mount /dev/sd<XZ> /mnt/boot/efi
```

## Installation

1. Install `git`:
```
pacman -Syy git
```

2. Clone repo:
```
git clone https://github.com/jhwshin/arch-install.git
```

3. Read and modify script variables according to system (e.g mirrors, locale, drivers, etc):
```
cd arch-install
nano arch-install.sh
```

4. Run script:
```
bash arch-install.sh
```

5. Once installation is finished you may `chroot` back to `/mnt` to check, modify or add anything else to the system:
```
arch-chroot /mnt
```

6. Otherwise simply unmount and reboot to your new Arch system!
```
umount -R /mnt
reboot
```

## TODO:

* LightDM
* LVM
* LUKS encryption
* Log timestamps
