#!/bin/sh

echo "Enabling networking"
systemctl restart systemd-networkd
systemctl enable systemd-networkd
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
echo 'nameserver 8.8.4.4' >> /etc/resolv.conf

echo "Done! Enjoy your shiny new arch system :D"