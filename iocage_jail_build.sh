#!/bin/sh

# Set variables for jail name and IP address
JAIL_NAME="jail_name"
JAIL_IP="xxx.xxx.xxx.xxx"
JAIL_NETMASK="xx"
DOMAIN_NAME="example.com"
INTERFACE="eth0" #Check your interface name
ROOTPASS="root_password"

# Create a temporary JSON file for package installation
echo '{"pkgs":["nano","wget","bash","curl","sudo","p5-Net-Nslookup", "openssh-portable"]}' > /tmp/pkg.json

# Create the iocage jail
iocage create -b -n "${JAIL_NAME}" -p /tmp/pkg.json -r 13.2-RELEASE \
    dhcp=0 \
    vnet=1 \
    bpf=1 \
    ip4_addr="vnet0|${JAIL_IP}/${JAIL_NETMASK}" \
    defaultrouter="auto" \
    defaultrouter6=none \
    ip6_saddrsel=0 \
    resolver="none" \
    host_domainname="${DOMAIN_NAME}" \
    boot=1 \
    vnet_default_interface="${INTERFACE}" \
    allow_mlock=1

# Remove the temporary JSON file
rm /tmp/pkg.json

# Set allow_mlock for the jail
iocage set allow_mlock=1 "${JAIL_NAME}"

# Set bash as the default shell for root user in the jail
iocage exec "${JAIL_NAME}" chsh -s /usr/local/bin/bash root

# Create .bashrc file for root user
iocage exec "${JAIL_NAME}" touch /root/.bashrc

# Add custom prompt to .bashrc
# iocage exec "${JAIL_NAME}" echo "export PS1='[\u@\h \W]\\$ '" >> /root/.bashrc

# Set the default shell for new users to bash
iocage exec "${JAIL_NAME}" echo 'shell="/usr/local/bin/bash"' >> /etc/rc.conf

# Enable SSH in the jail
# Comment out if you do not need SSH set up by default
iocage exec "${JAIL_NAME}" sysrc sshd_enable="YES"

# Configure SSH to allow password authentication
# Comment out if you do not need SSH set up by default
iocage exec "${JAIL_NAME}" sed -i '' 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
iocage exec "${JAIL_NAME}" sed -i '' 's/^#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

# Set a password for the root user (replace 'your_password' with the desired password)
iocage exec "${JAIL_NAME}" pw usermod root -h 0 <<EOF
${ROOTPASS}
EOF

# Start the SSH service
# Comment out if you do not need SSH set up by default
iocage exec "${JAIL_NAME}" service sshd start

echo "Jail '${JAIL_NAME}' created with IP ${JAIL_IP}/${JAIL_NETMASK} and SSH enabled with password authentication"

