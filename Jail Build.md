# FreeBSD Jail Creation Script

This document explains the usage of the jail creation script for FreeBSD systems using iocage.

## Overview

The script automates the process of creating a FreeBSD jail with specific configurations, including network settings, package installations, and SSH setup. It's designed to be run on the host FreeBSD system.

## Prerequisites

- FreeBSD 13.2 or later
- iocage installed and configured
- Root access to the FreeBSD host system

## Usage

1. Upload the script to a location on the main FreeBSD file system, such as `/tmp`.
2. Make the script executable: chmod +x /tmp/iocage_jail_build.sh
3. Edit the script to set the following variables according to your requirements:
- `JAIL_NAME`: Name of the jail
- `JAIL_IP`: IP address for the jail
- `JAIL_NETMASK`: Netmask for the jail's network
- `DOMAIN_NAME`: Domain name for the jail
- `INTERFACE`: Network interface to use (e.g., "eth0")
- `ROOTPASS`: Password for the root user in the jail

4. Run the script as root from the main FreeBSD shell console: /tmp/iocage_jail_build.sh

## Script Functions

The script performs the following actions:

1. Creates a temporary JSON file for package installation.
2. Creates an iocage jail with specified network settings and packages.
3. Sets bash as the default shell for the root user.
4. Configures SSH to allow password authentication (optional).
5. Sets a password for the root user.
6. Starts the SSH service (optional).

## Customization

- To modify the packages installed in the jail, edit the JSON array in the `echo` command at the beginning of the script.
- SSH setup can be disabled by commenting out the relevant sections in the script.

## Security Considerations

- The script enables password authentication for SSH by default. For production environments, it's recommended to use key-based authentication instead.
- The root password is set directly in the script. Ensure to change this for production use or implement a more secure method of password setting.

## Post-Installation

After running the script, you can access the jail using: iocage console JAIL_NAME

Or via SSH if enabled: ssh root@JAIL_IP

Remember to change the root password and configure any additional services as needed for your specific use case. The SSH function utilises password authentication for ease instead of the more secure keys method. If you need to retain SSH acess after installation, it is advisable to implement more secure authentication methods.
