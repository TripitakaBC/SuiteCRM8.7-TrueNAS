# SuiteCRM 8.7.0 TrueNAS CORE / FreeBSD Installation Script

## Purpose

This script automates the installation of SuiteCRM 8.7.0 on a FreeBSD system. It's designed to simplify the setup process and ensure that all necessary components are installed and configured correctly.

## Features

- Automates the installation of SuiteCRM 8.7.0
- Installs and configures Apache, PHP, and MariaDB
- Sets up the database and user for SuiteCRM
- Configures PHP and Apache for optimal performance with SuiteCRM
- Sets appropriate file permissions
- Provides a secure installation with a randomly generated MySQL root password

## Prerequisites

- FreeBSD 13.2 or later
- Root access to the system
- Internet connection for downloading packages

## Jail Build

- A jail build script is provided (jail_build.sh)
- Edit the variables in the script to your needs
- Start at the main Truenas shell and copy the jail_build.sh to the /tmp directory
- CD /tmp and 'bash jail_build.sh'
- Switch to the jail shell when built

## Variables

The script uses the following variables which can be customized:

- `SUITECRM_VERSION`: Version of SuiteCRM to install (default: "8.7.0")
- `MYSQL_USERNAME`: Username for the SuiteCRM database (default: "suitecrm")
- `MYSQL_PASSWORD`: Password for the SuiteCRM database user
- `MYSQL_DATABASE`: Name of the database for SuiteCRM (default: "suitecrm")
- `SERVER_NAME`: Server name or IP address
- `SERVER_URL`: Full URL to access SuiteCRM

## Usage

1. Clone this repository or download the script.
2. Review and modify the variables at the top of the script if needed.
3. Make the script executable: chmod +x suitecrm_install.sh
4. Run the script as root: ./suitecrm_install.sh
5. Follow any on-screen prompts during the installation process.
6. Once the script completes, access the SuiteCRM installation page via a web browser to finish the setup.

## Post-Installation

- The MySQL root password is randomly generated and displayed at the end of the installation. Make sure to save this password securely.
- Complete the SuiteCRM setup through the web interface.
- Review Apache and PHP configurations for any additional customizations needed for your environment.

## Troubleshooting

- Check the installation log at `/tmp/installation.log` for any errors.
- Ensure all required ports are open if accessing SuiteCRM remotely.
- Verify file permissions if you encounter access issues.

## Contributing

Contributions to improve the script are welcome. Please submit pull requests or open issues for any bugs or enhancements.

## Disclaimer

This script is provided as-is, without any warranties. Always review scripts before running them on your system and ensure you have proper backups.

## License

[MIT License](LICENSE)


