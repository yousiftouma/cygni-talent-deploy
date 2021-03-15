#/bin/bash

set -e
SERVER=68.183.221.185

# setup user
if ssh -q lenkan@$SERVER exit; then
    echo "ssh connection for lenkan accepted, skipping user setup"
else
ssh root@$SERVER <<EOF
    set -e;

    if id lenkan &>/dev/null; then
        echo "user \"lenkan\" already exists";
    else
        adduser lenkan --disabled-password --ingroup sudo --gecos "";
    fi;

    echo "lenkan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/lenkan;
    chmod 440 /etc/sudoers.d/lenkan;
    visudo --check;

    mkdir -p /home/lenkan/.ssh;
    touch /home/lenkan/.ssh/authorized_keys;
    chown -R lenkan /home/lenkan/.ssh;
    chmod 644 /home/lenkan/.ssh/authorized_keys;
EOF

cat ~/.ssh/id_rsa.pub | ssh root@$SERVER "cat - > /home/lenkan/.ssh/authorized_keys"
fi


# dependencies
ssh lenkan@$SERVER <<EOF
    set -e;

    echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/setup.conf;

    sudo adduser --system cygni;

    curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -;
    sudo apt update;
    sudo apt install -y ufw nodejs;

    sudo ufw default deny incoming; 
    sudo ufw default allow outgoing; 
    sudo ufw allow ssh; 
    sudo ufw allow http; 
    sudo ufw allow in 8080/tcp;
    sudo ufw --force enable;

    sudo systemctl restart sshd;
EOF
