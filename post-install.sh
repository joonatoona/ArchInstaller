#!/bin/sh

echo "Enabling networking"
systemctl restart systemd-networkd
systemctl enable systemd-networkd
cat > /etc/resolv.conf << EOF
nameserver 84.200.69.80
nameserver 84.200.70.40
nameserver 2001:1608:10:25::1c04:b12f
nameserver 2001:1608:10:25::9249:d69b
nohook resolv.conf
EOF

echo "Done! Enjoy your shiny new arch system :D"
