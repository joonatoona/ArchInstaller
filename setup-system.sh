#!/bin/sh

ip link
echo -n "Network interface to use? : "
read interface

echo -n "Hostname? : "
read hostname

echo -n "Username? : "
read username

echo "Installing needed packages"
pacman -S grub os-prober efibootmgr sudo dialog --noconfirm

echo "Setting timezone"
ln -sf /usr/share/zoneinfo/US/Pacific /etc/localtime
hwclock --systohc

echo "Setting Locale"
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo "Setting Hostname"
echo $hostname > /etc/hostname
echo "127.0.0.1 $hostname.localdomain $hostname" >> /etc/hosts

echo "Installing bootloader"
grub-install --target=x86_64-efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "Configuring network"
echo '[Match]' > /etc/systemd/network/$interface.network
echo 'Name=en*' >> /etc/systemd/network/$interface.network
echo '' >> /etc/systemd/network/$interface.network
echo '[Network]' >> /etc/systemd/network/$interface.network
echo 'DHCP=yes' >> /etc/systemd/network/$interface.network

echo "Creating user account"
useradd -mg users -G wheel,storage,power -s /bin/bash $username
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
echo "Please set password"
passwd $username

echo "Done!"
echo "Please leave chroot and reboot"