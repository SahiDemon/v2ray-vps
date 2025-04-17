#!/bin/bash

# Sahidemon - Combined V2Ray Panel & SSL Installation Script
# Based on scripts for X-UI installation and V2Ray+SSL setup.

export LANG=en_US.UTF-8

# --- Color Codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m' # Alias for NC
NC='\033[0m'    # No Color

# --- Helper Functions ---
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check the exit status of the last command
check_status() {
    if [ $? -ne 0 ]; then
        print_error "$1 failed. Exiting."
        # Optional: Add cleanup logic here if needed
        exit 1
    fi
}

# --- OS Detection Variables (from Script 2) ---
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora" "Alpine")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install" "apk add -f")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove" "apk del -f")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove" "apk del -f")

# --- SSL Configuration ---
CERT_KEY_PATH="/root/sahidemon.key" # Changed path slightly for branding
CERT_FULLCHAIN_PATH="/root/sahidemon.crt" # Changed path slightly for branding
ACME_SCRIPT_PATH="$HOME/.acme.sh/acme.sh"
XUI_INSTALL_URL="https://raw.githubusercontent.com/SahiDemon/v2ray-vps/refs/heads/main/install.sh?token=GHSAT0AAAAAAC7Y62SPOG3Z2KDKKGTPHLLG2AA3SEQ" # Using the URL from Script 1 for X-UI install part


# --- Pre-flight Checks ---
print_info "Starting Sahidemon Setup Script..."

# 1. Check for Root Privileges
if [[ $EUID -ne 0 ]]; then
  print_error "This script must be run as root user! Please use 'sudo bash $0'."
  exit 1
fi

# --- OS/Arch Detection & Validation (from Script 2) ---
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

SYSTEM=""
OS_INT=-1
for ((int = 0; int < ${#REGEX[@]}; int++)); do
    if [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]]; then
        SYSTEM="${RELEASE[int]}"
        OS_INT=$int
        [[ -n $SYSTEM ]] && break
    fi
done

if [[ -z $SYSTEM ]] || [[ $OS_INT -eq -1 ]]; then
    print_error "Script doesn't support your operating system ($SYS). Please use a supported one (Debian, Ubuntu, CentOS, Fedora, Alpine)."
    exit 1
fi
print_info "Detected OS: $SYSTEM"

os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

# OS Version Checks
case $SYSTEM in
    "CentOS") [[ ${os_version} -lt 7 ]] && print_error "Please use CentOS 7 or higher." && exit 1 ;;
    "Fedora") [[ ${os_version} -lt 29 ]] && print_error "Please use Fedora 29 or higher." && exit 1 ;;
    "Ubuntu") [[ ${os_version} -lt 16 ]] && print_error "Please use Ubuntu 16 or higher." && exit 1 ;;
    "Debian") [[ ${os_version} -lt 9 ]] && print_error "Please use Debian 9 or higher." && exit 1 ;;
esac
print_info "OS Version ($os_version) is supported."

# Architecture Check
archAffix(){
    case "$(uname -m)" in
        x86_64 | x64 | amd64 ) echo 'amd64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        s390x ) echo 's390x' ;;
        * ) print_error "Unsupported CPU architecture: $(uname -m)" && exit 1 ;;
    esac
}
ARCH=$(archAffix)
print_info "Detected Architecture: $ARCH"

# --- Rebranded Info Bar ---
info_bar(){
    clear
    echo -e "${GREEN}----------------------------------------------------------------------${PLAIN}"
    echo -e "${GREEN}   _____          _ _     _       _                              ${PLAIN}"
    echo -e "${GREEN}  / ____|        (_) |   (_)     | |                             ${PLAIN}"
    echo -e "${GREEN} | (___   __ _ __ _| |__  _ _ __ | | ___  _ __ ___   ___  _ __   ${PLAIN}"
    echo -e "${GREEN}  \\___ \\ / _\` | '__| | '_ \\| | '_ \\| |/ _ \\| '_ \` _ \\ / _ \\| '_ \\  ${PLAIN}"
    echo -e "${GREEN}  ____) | (_| | |  | | |_) | | | | | | (_) | | | | | | (_) | | | | ${PLAIN}"
    echo -e "${GREEN} |_____/ \\__,_|_|  |_|_.__/|_|_| |_|_|\\___/|_| |_| |_|\\___/|_| |_| ${PLAIN}"
    echo -e "${GREEN}----------------------------------------------------------------------${PLAIN}"
    echo -e "${GREEN}            Combined V2Ray Panel & SSL Installation Script             ${PLAIN}"
    echo -e "${GREEN}----------------------------------------------------------------------${PLAIN}"
    echo ""
    echo -e "OS: ${GREEN}${SYS} (${SYSTEM} ${os_version})${PLAIN}"
    echo -e "Architecture: ${GREEN}${ARCH}${PLAIN}"
    echo ""
    sleep 2
}

# --- Network Check (Adapted from Script 2's check_status) ---
check_network(){
    print_info "Checking server's IP configuration environment..." && sleep 1
    local WgcfIPv4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    local WgcfIPv6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
    local v4=""
    local v6=""

    if [[ $WgcfIPv4Status =~ "on"|"plus" ]] || [[ $WgcfIPv6Status =~ "on"|"plus" ]]; then
        print_warning "WARP connection detected. Temporarily disabling to check public IPs."
        wg-quick down wgcf >/dev/null 2>&1
        v6=$(curl -s6m8 ip.gs -k || curl -s6m8 api64.ipify.org -k)
        v4=$(curl -s4m8 ip.gs -k || curl -s4m8 api.ipify.org -k)
        print_info "Re-enabling WARP connection."
        wg-quick up wgcf >/dev/null 2>&1
    else
        v6=$(curl -s6m8 ip.gs -k || curl -s6m8 api64.ipify.org -k)
        v4=$(curl -s4m8 api.ipify.org -k || curl -s4m8 ip.gs -k)
    fi

    if [[ -z $v4 && -n $v6 ]]; then
        print_warning "IPv6 Only VPS detected. Adding DNS64 nameserver."
        # Make sure /etc/resolv.conf exists and is writable
        if [ -w /etc/resolv.conf ]; then
            echo -e "nameserver 2a01:4ff:ff00::add:1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
        else
             print_warning "Cannot write to /etc/resolv.conf to add DNS64 server."
        fi
    elif [[ -z $v4 && -z $v6 ]]; then
         print_warning "Could not determine public IP address (IPv4 or IPv6). Network checks might fail."
    else
        print_success "Public IP detected: IPv4 ($v4) / IPv6 ($v6)"
    fi
    # Store detected IPs globally for later use in output
    public_v4=$v4
    public_v6=$v6
    sleep 1
}


# --- Base Dependency Installation (Combined) ---
install_base(){
    print_info "Updating package lists..."
    ${PACKAGE_UPDATE[OS_INT]}
    check_status "Package list update"

    print_info "Installing base dependencies (curl, wget, tar, socat, ca-certificates)..."
    local packages_to_install="curl wget tar ca-certificates"

    # Add socat for Debian/Ubuntu, yum equivalent if needed for others
    if [[ "$SYSTEM" == "Debian" || "$SYSTEM" == "Ubuntu" ]]; then
        packages_to_install+=" socat"
    elif [[ "$SYSTEM" == "CentOS" || "$SYSTEM" == "Fedora" ]]; then
         packages_to_install+=" socat" # socat is usually available in EPEL for CentOS, or base for Fedora
    fi
    # Add other OS specific dependencies here if necessary

    ${PACKAGE_INSTALL[OS_INT]} $packages_to_install
    check_status "Base dependency installation ($packages_to_install)"
    print_success "Base dependencies installed."
}


# --- User Input for SSL ---
get_ssl_input() {
    email=""
    domain=""

    # 1. Get and Validate Email
    while true; do
        read -p "Enter email address (for SSL certificate registration): " email
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            print_info "Email format appears valid: $email"
            break
        else
            print_warning "Invalid email format. Please try again."
        fi
    done

    # 2. Get and Validate Domain
    while true; do
        read -p "Enter your domain (e.g., host.mydomain.com): " domain
        if [ -z "$domain" ]; then
            print_warning "Domain cannot be empty."
        elif [[ "$domain" == *" "* ]] || [[ "$domain" != *"."* ]]; then
             print_warning "Invalid domain format (e.g., host.mydomain.com). No spaces allowed, must contain dots."
        else
            print_info "Domain format appears valid: $domain"
            break
        fi
    done

    print_warning "Ensure your domain '$domain' points to this server's public IP."
    print_warning "Ensure port 80 is open/accessible for Let's Encrypt validation."
    read -p "Press Enter to continue if the above conditions are met..."
    # Store globally
    ssl_email=$email
    ssl_domain=$domain
}


# --- X-UI Panel Installation/Update (Adapted from Script 2) ---
install_update_xui() {
    local xui_installed=false
    if [[ -e /usr/local/x-ui/ ]]; then
        xui_installed=true
        print_warning "An existing X-UI installation found."
        read -rp "Do you want to update it? (Existing database will be backed up) [y/n, default n]: " yn
        if [[ ! $yn =~ "Y"|"y" ]]; then
            print_info "Skipping X-UI installation/update."
            # Try to read existing config for output later
            config_port=$(/usr/local/x-ui/x-ui setting -show true | grep port | awk '{print $2}')
            config_account=$(/usr/local/x-ui/x-ui setting -show true | grep username | awk '{print $2}')
            # Password cannot be retrieved easily, inform user
            config_password="<Existing Password - Not Shown>"
            return 0 # Skip the rest of the installation
        fi
        print_info "Proceeding with X-UI update..."
        # Backup logic from Script 2
        print_info "Backing up existing database..."
        mv /etc/x-ui/x-ui.db /etc/x-ui-english.db.bak.$(date +%s) 2>/dev/null
        mv /etc/x-ui-english/x-ui-english.db /etc/x-ui-english.db.bak.$(date +%s) 2>/dev/null
        check_status "Database backup (Note: errors may occur if previous db doesn't exist)"

        print_info "Stopping and disabling existing X-UI service..."
        systemctl stop x-ui >/dev/null 2>&1
        systemctl disable x-ui >/dev/null 2>&1
        rm /etc/systemd/system/x-ui.service -f
        systemctl daemon-reload
        systemctl reset-failed
        print_info "Removing old X-UI files..."
        rm /etc/x-ui/ -rf
        rm /usr/local/x-ui/ -rf
        rm /usr/bin/x-ui -f
        print_success "Old X-UI version removed."
    fi

    # Download X-UI (Latest Version)
    print_info "Downloading latest X-UI version..."
    local last_version=$(curl -Ls "https://api.github.com/repos/NidukaAkalanka/x-ui-english/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    # Fallback if API fails
    [[ -z "$last_version" ]] && last_version=$(curl -sm8 https://raw.githubusercontent.com/NidukaAkalanka/x-ui-english/main/config/version)

    if [[ -z "$last_version" ]]; then
        print_error "Detecting the latest X-UI version failed. Check Github connectivity."
        exit 1
    fi
    print_info "Latest version: ${last_version}. Downloading..."
    local download_url="https://github.com/NidukaAkalanka/x-ui-english/releases/download/${last_version}/x-ui-linux-${ARCH}.tar.gz"
    wget -N --no-check-certificate -O "/usr/local/x-ui-linux-${ARCH}.tar.gz" "$download_url"
    check_status "X-UI download (${last_version})"

    # Install X-UI
    print_info "Installing X-UI..."
    cd /usr/local/ || exit 1
    tar zxvf "x-ui-linux-${ARCH}.tar.gz"
    check_status "Extracting X-UI archive"
    rm -f "x-ui-linux-${ARCH}.tar.gz"

    cd x-ui || exit 1
    chmod +x x-ui "bin/xray-linux-${ARCH}"
    cp -f x-ui.service /etc/systemd/system/
    check_status "Copying systemd service file"

    print_info "Setting up 'x-ui' command..."
    wget -N --no-check-certificate https://raw.githubusercontent.com/SahiDemon/v2ray-vps/refs/heads/main/x-ui.sh?token=GHSAT0AAAAAAC7Y62SPBX44UOENQEYNXKJI2AA3TPA -O /usr/bin/x-ui
    check_status "Downloading x-ui command script"
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    cd "$HOME" # Go back to home directory

    # Restore Backup if updating
    if $xui_installed; then
         print_info "Attempting to restore database backup..."
         mkdir -p /etc/x-ui-english # Ensure directory exists
         # Find the latest backup
         latest_backup=$(ls -t /etc/x-ui-english.db.bak.* 2>/dev/null | head -n 1)
         if [[ -f "$latest_backup" ]]; then
             mv "$latest_backup" /etc/x-ui-english/x-ui-english.db
             check_status "Restoring database backup"
             print_success "Database restored from $latest_backup."
         else
             print_warning "No suitable database backup found to restore. Panel will start fresh."
         fi
    fi

    # Configure Panel (Only if not restoring DB or restore failed)
    if ! $xui_installed || [[ ! -f "/etc/x-ui-english/x-ui-english.db" ]]; then
        print_info "Configuring new X-UI panel settings..."
        print_warning "For security, please note down the generated/chosen credentials."
        read -rp "Set login username [default: random]: " config_account_input
        [[ -z $config_account_input ]] && config_account_input=$(date +%s%N | md5sum | cut -c 1-8)
        config_account=$config_account_input # Store globally

        read -rp "Set login password (no spaces) [default: random]: " config_password_input
        [[ -z $config_password_input ]] && config_password_input=$(date +%s%N | md5sum | cut -c 1-8)
        config_password=$config_password_input # Store globally

        read -rp "Set panel access port [default: random between 1000-65535]: " config_port_input
        [[ -z $config_port_input ]] && config_port_input=$(shuf -i 1000-65535 -n 1)

        # Port validation
        while [[ -z "$config_port_input" ]] || ! [[ "$config_port_input" =~ ^[0-9]+$ ]] || (( config_port_input < 1 || config_port_input > 65535 )) || ss -tuln | grep -q ":$config_port_input "; do
            if ss -tuln | grep -q ":$config_port_input "; then
                 print_warning "Port $config_port_input is already in use."
            else
                 print_warning "Invalid port number."
            fi
            read -rp "Please choose a different port [default: random]: " config_port_input
            [[ -z $config_port_input ]] && config_port_input=$(shuf -i 1000-65535 -n 1)
        done
        config_port=$config_port_input # Store globally

        /usr/local/x-ui/x-ui setting -username "${config_account}" -password "${config_password}" >/dev/null 2>&1
        check_status "Setting panel username/password"
        /usr/local/x-ui/x-ui setting -port "${config_port}" >/dev/null 2>&1
        check_status "Setting panel port"
        print_success "Panel configured."
    else
        print_info "Using settings from restored database."
        # Attempt to read config from restored db/files for final output
        config_port=$(/usr/local/x-ui/x-ui setting -show true | grep port | awk '{print $2}')
        config_account=$(/usr/local/x-ui/x-ui setting -show true | grep username | awk '{print $2}')
        config_password="<Restored Password - Not Shown>"
    fi

    # Start and Enable Service
    print_info "Enabling and starting X-UI service..."
    systemctl daemon-reload
    systemctl enable x-ui >/dev/null 2>&1
    systemctl start x-ui
    check_status "Starting X-UI service"
    sleep 2 # Give service time to start
    systemctl restart x-ui # Sometimes a restart helps solidify things

    local status=$(systemctl is-active x-ui)
    if [[ "$status" == "active" ]]; then
        print_success "X-UI panel service is active."
    else
        print_error "X-UI service failed to start. Status: $status"
        print_warning "Check logs using 'x-ui log' or 'journalctl -u x-ui'."
        # Decide whether to exit or continue with SSL attempt
        # exit 1
    fi

    print_success "X-UI v${last_version} Installation / Update Completed."
}


# --- SSL Certificate Management (acme.sh) ---
install_acme() {
    print_info "Installing/Updating Acme.sh script..."
    # Check if already installed
    if [ -f "$ACME_SCRIPT_PATH" ]; then
        print_info "Acme.sh already installed. Checking for updates..."
        "$ACME_SCRIPT_PATH" --upgrade --auto-upgrade
    else
        curl https://get.acme.sh | sh -s email="$ssl_email"
        check_status "Acme.sh installation script download/execution"
    fi

    if [ ! -f "$ACME_SCRIPT_PATH" ]; then
        print_error "Acme.sh installation failed (script not found at $ACME_SCRIPT_PATH)."
        exit 1
    fi
    print_success "Acme.sh installed/updated."

    print_info "Setting default CA to Let's Encrypt..."
    "$ACME_SCRIPT_PATH" --set-default-ca --server letsencrypt
    # Don't exit on failure, just warn
    [ $? -ne 0 ] && print_warning "Could not set Let's Encrypt as default CA. Proceeding anyway." || print_success "Default CA set to Let's Encrypt."
}

register_acme_account() {
    print_info "Registering Acme.sh account with Let's Encrypt ($ssl_email)..."
    "$ACME_SCRIPT_PATH" --register-account -m "$ssl_email" --server letsencrypt
    # Check status but allow to continue if it fails (e.g., account already registered)
     if [ $? -ne 0 ]; then
        print_warning "Acme.sh account registration command finished with non-zero status. Might be already registered."
    else
        print_success "Acme.sh account registered/verified for $ssl_email."
     fi
}

issue_certificate() {
    print_info "Attempting to obtain SSL certificate for '$ssl_domain' (using standalone mode)..."
    print_warning "This requires port 80 to be free and accessible from the internet."
    print_info "Stopping X-UI temporarily if running, to free up potential port conflicts..."
    systemctl stop x-ui >/dev/null 2>&1 # Stop x-ui in case it uses port 80

    # Issue with ECC key type
    "$ACME_SCRIPT_PATH" --issue -d "$ssl_domain" --standalone --keylength ec-256 --server letsencrypt
    local issue_status=$?

    print_info "Restarting X-UI service..."
    systemctl start x-ui # Start x-ui again

    if [ $issue_status -ne 0 ]; then
        print_error "SSL certificate issuance failed. Please check:"
        print_error " - Domain '$ssl_domain' points correctly to this server's IP ($public_v4 / $public_v6)."
        print_error " - Port 80 is not blocked by a firewall (check ufw, iptables, cloud firewall)."
        print_error " - No other service was listening on port 80 during validation."
        print_error " - Let's Encrypt rate limits have not been exceeded."
        print_error " - Check Acme.sh logs in $HOME/.acme.sh/acme.sh.log"
        # Decide if script should exit or just warn
        exit 1 # Exit because subsequent steps depend on the cert
    fi
    print_success "SSL certificate obtained successfully for $ssl_domain."
}

install_certificate() {
    print_info "Installing SSL certificate to '$CERT_FULLCHAIN_PATH' and key to '$CERT_KEY_PATH'..."
    mkdir -p "$(dirname "$CERT_KEY_PATH")" # Ensure /root exists (should!)

    "$ACME_SCRIPT_PATH" --install-cert -d "$ssl_domain" \
        --key-file       "$CERT_KEY_PATH" \
        --fullchain-file "$CERT_FULLCHAIN_PATH" \
        --ecc # Necessary because we used --keylength ec-256

    check_status "SSL certificate installation"

    # Verify files exist and set permissions
    if [ ! -f "$CERT_KEY_PATH" ] || [ ! -f "$CERT_FULLCHAIN_PATH" ]; then
        print_error "Certificate installation failed - key or cert file not found at expected location."
        exit 1
    fi
    chmod 600 "$CERT_KEY_PATH" # Restrict permissions on private key
    print_success "SSL certificate installed and key permissions set."
}

# --- Final Output Function ---
show_final_summary() {
    print_success "-----------------------------------------------------"
    print_success " Sahidemon Setup Completed!                          "
    print_success "-----------------------------------------------------"
    print_info "Summary:"
    print_info " - OS: ${SYS} (${SYSTEM} ${os_version})"
    print_info " - Arch: ${ARCH}"
    print_info " - Base dependencies installed."
    print_info " - X-UI Panel (v${last_version:-Unknown}) installed/updated."
    print_info " - SSL certificate for '$ssl_domain' obtained and installed:"
    print_info "   - Cert Path: ${GREEN}$CERT_FULLCHAIN_PATH${NC}"
    print_info "   - Key Path:  ${GREEN}$CERT_KEY_PATH${NC} (Permissions set to 600)"

    print_warning "\n--- Panel Access Info ---"
    # Use detected IPs and configured port/user/pass
    if [[ -n $public_v4 ]]; then
        print_info "Panel IPv4 URL: ${GREEN}http://$public_v4:$config_port${NC}"
    fi
     if [[ -n $public_v6 ]]; then
        print_info "Panel IPv6 URL: ${GREEN}http://[$public_v6]:$config_port${NC}"
    fi
    print_info "Username: ${GREEN}$config_account${NC}"
    print_info "Password: ${GREEN}$config_password${NC}" # Note: will show placeholder if restored

    print_warning "\n--- Important Next Steps ---"
    print_warning "1. Configure X-UI Panel for SSL:"
    print_warning "   - Login to the panel using the details above."
    print_warning "   - Go to 'Panel Settings'."
    print_warning "   - Enter the Cert Path: $CERT_FULLCHAIN_PATH"
    print_warning "   - Enter the Key Path:  $CERT_KEY_PATH"
    print_warning "   - Save settings and restart the panel if prompted."
    print_warning "   - You should then be able to access the panel via HTTPS: https://$ssl_domain:$config_port"
    print_warning "2. Configure V2Ray Inbounds:"
    print_warning "   - Set up your V2Ray inbound proxies within the X-UI panel."
    print_warning "   - For TLS-enabled protocols (like VLESS/VMess+TLS), use the same Cert and Key paths."
    print_warning "3. Firewall:"
    print_warning "   - Ensure your firewall allows traffic on:"
    print_warning "     - Panel Port: $config_port (TCP)"
    print_warning "     - V2Ray Ports: Typically 443 (TCP) for TLS, and any other ports you configure."
    print_warning "     - Example (ufw): sudo ufw allow $config_port/tcp; sudo ufw allow 443/tcp"
    print_warning "4. Reboot (Optional):"
    print_warning "   - If the system upgraded the kernel ('apt upgrade' output), a reboot ('sudo reboot') is recommended."
    print_warning "5. X-UI Management:"
    print_warning "   - Use the 'x-ui' command for managing the panel (start, stop, logs, etc.)."

    echo -e "\n------------------------------------------------------------------------------"
    echo -e                            "<<<<SAHIDEMON>>>>"
    echo -e "------------------------------------------------------------------------------"

}


# --- Main Execution Flow ---

info_bar
install_base # Install curl, wget, socat, etc.
check_network # Check public IPs

get_ssl_input # Get email and domain for certs

# Install/Update X-UI first, configure its basic settings
install_update_xui

# Now handle SSL Certificates
install_acme
register_acme_account
issue_certificate   # Requires port 80
install_certificate # Installs cert/key to specified paths

# Show combined summary and next steps
show_final_summary

exit 0
