#!/bin/bash
set -e

# Create user with ssh access
scp -F .ssh/config .ssh/admin.pub root@cygni:/tmp/admin.pub
ssh -t -F .ssh/config root@cygni "
    id -u admin && deluser admin && rm -rf /home/admin
    adduser admin --ingroup sudo --gecos \"\"

    mkdir -p /home/admin/.ssh
    mv /tmp/admin.pub /home/admin/.ssh/authorized_keys

    chown admin /home/admin/.ssh
    chmod 644 /home/admin/.ssh/authorized_keys
"

# Restrict root access to host machine
echo "
PermitRootLogin no
PasswordAuthentication no
" | ssh -F .ssh/config admin@cygni "cat - > /tmp/sshd_config"

ssh -t -F .ssh/config admin@cygni "sudo mv /tmp/sshd_config /etc/ssh/sshd_config.d/setup.conf && sudo systemctl restart sshd"
