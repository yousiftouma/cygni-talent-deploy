#!/bin/bash
# Run this script to set up an admin user with passwordless sudo priviliges

SERVER=68.183.221.185
ADMIN_USER=lenkan
ADMIN_PUBLIC_KEY_FILE=./.ssh/admin.pub
ADMIN_KEY_FILE=./.ssh/admin
SSH_CONFIG_FILE=./.ssh/config

# Print ssh config file
echo "
Host root
    HostName $SERVER
    IdentityFile ~/.ssh/id_rsa
    # PasswordAuthentication yes
    User root

Host admin
    HostName $SERVER
    IdentityFile $ADMIN_KEY_FILE
    User $ADMIN_USER
" > $SSH_CONFIG_FILE

set -e

# Prepare ssh keys
if test -f $ADMIN_KEY_FILE; then
    echo "$ADMIN_KEY_FILE already exists, skipping ssh-keygen"
else
    ssh-keygen -f $ADMIN_KEY_FILE -t rsa -b 4096 -C "email"
fi

# Create user with ssh access
ssh -F $SSH_CONFIG_FILE root "id -u $ADMIN_USER && deluser $ADMIN_USER && rm -rf /home/$ADMIN_USER"
ssh -t -F $SSH_CONFIG_FILE root "adduser $ADMIN_USER --ingroup sudo --gecos \"\""
ssh -F $SSH_CONFIG_FILE root <<EOF
    mkdir -p /home/$ADMIN_USER/.ssh
    chown $ADMIN_USER /home/$ADMIN_USER/.ssh
    touch $ADMIN_USER /home/$ADMIN_USER/.ssh/authorized_keys
    chmod 644 /home/$ADMIN_USER/.ssh/authorized_keys
EOF
ssh -F $SSH_CONFIG_FILE root "tee /home/$ADMIN_USER/.ssh/authorized_keys" < $ADMIN_PUBLIC_KEY_FILE
    
# Finally, restrict root access to host machine
echo "
PermitRootLogin no
PasswordAuthentication no
" | ssh -F $SSH_CONFIG_FILE admin "cat - > /tmp/sshd_config"
ssh -t -F $SSH_CONFIG_FILE admin "sudo mv /tmp/sshd_config /etc/ssh/sshd_config.d/setup.conf && sudo systemctl restart sshd"

