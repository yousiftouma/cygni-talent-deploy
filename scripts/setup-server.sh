#!/bin/bash
set -e

ssh -t -F .ssh/config admin@cygni "
    set -e

    echo \"Install dependencies\"
    curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt update
    sudo apt install -y ufw nodejs

    echo \"Setting up firewall\"
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow in 8080/tcp
    sudo ufw --force enable
"
