#!/bin/bash
set -euo pipefail

echo -n "Hostname: "
read hostname

echo -n "Username: "
read username

fdisk -l | grep 'Disk /dev/' | cat
echo "The disk you select WILL BE ERASED"
echo -ne "Disk to OVERWRITE: "
read disk

echo -ne "Type yes in all caps to erase $disk: "
read confirm

if [[ "$confirm" != "YES" ]]; then
    echo "Aborting"
    exit 0
fi

echo "Partitioning disks..."
echo -ne "n\n\n\n+100M\nEF00\nn\n\n\n\n8E00\nw\ny\n" | gdisk "$disk" &> /tmp/disk-log

echo "Encrypting main partition"
cryptsetup luksFormat --type luks2 "$disk"2
cryptsetup open "$disk"2 root

echo "Creating LVM"
pvcreate /dev/mapper/root
vgcreate "$hostname" /dev/mapper/root
lvcreate -L 8G "$hostname" -n swap
lvcreate -L 32G "$hostname" -n root
lvcreate -L 100%FREE "$hostname" -n home

echo "Creating filesystems"
mkfs.vfat -F32 "$disk"1
mkfs.ext4 /dev/"$hostname"/root
mkfs.ext4 -m 0 /dev/"$hostname"/home
mkswap /dev/"$hostname"/swap

echo "Mounting filesystems"
mount /dev/mapper/root /mnt
mkdir -p /mnt/etc /mnt/boot
mount "$disk"1 /mnt/boot
swapon /dev/"$hostname"/swap
genfstab -U /mnt >> /mnt/etc/fstab

echo "Boostraping system"
pacstrap /mnt base
cat << SCRIPT_EOF | arch-chroot /mnt bash
set -euo pipefail

pacman -S grub sudo dialog efibootmgr --noconfirm
ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime
hwclock --systohc

echo $hostname > /etc/hostname
echo "127.0.0.1 $hostname.localdomain $hostname" >> /etc/hosts

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

cat >> /etc/pacman.conf << EOF
[digitalfishfun]
Server = https://digitalfishfun.com/repo/x86_64
EOF

mv -v /etc/mkinitcpio.conf /etc/mkinitcpio.conf.old
sed "s/^MODULES=\"\"/MODULES=\"ext4\"/" /etc/mkinitcpio.conf.old | sed "/^HOOKS=/s/filesystems/encrypt lvm2 resume filesystems/" > /etc/mkinitcpio.conf
mkinitcpio -P linux

sed -i 's!quiet!quiet cryptdevice=$disk:root root=/dev/mapper/$hostname-root!' /etc/default/grub
grub-install --efi-directory=/boot --target=x86_64-efi --bootloader-id=tfarch

useradd -mg users -G wheel,storage,power -s /bin/bash $username
as
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
passwd $username

SCRIPT_EOF

echo "Ready! Press enter to reboot into your new system :3"
read
reboot
