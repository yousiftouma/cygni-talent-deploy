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
    echo $(cat ~/.ssh/id_rsa.pub) | sudo tee /home/lenkan/.ssh/authorized_keys >/dev/null;
    chown -R lenkan /home/lenkan/.ssh;
    chmod 644 /home/lenkan/.ssh/authorized_keys;
EOF
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

# setup deploy user
if test -f .ssh/deploy; then
    echo ".ssh/deploy already exists"
else
    mkdir -p .ssh
    ssh-keygen -f .ssh/deploy -t rsa -b 4096
    ssh-keyscan $SERVER > .ssh/known_hosts
    echo ".ssh/deploy created"
fi


if ssh -q -i .ssh/deploy deploy@$SERVER exit; then
    echo "ssh connection for deploy accepted, skipping user setup"
else
ssh lenkan@$SERVER <<EOF
    set -e;

    if id deploy &>/dev/null; then
        echo "user \"deploy\" already exists";
    else
        sudo adduser deploy --disabled-password --ingroup sudo --gecos "";
    fi;

    echo "deploy ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/deploy;
    sudo chmod 440 /etc/sudoers.d/deploy;
    sudo visudo --check;

    sudo mkdir -p /home/deploy/.ssh;
    echo $(cat .ssh/deploy.pub) | sudo tee /home/deploy/.ssh/authorized_keys >/dev/null;
    sudo chown -R deploy /home/deploy/.ssh;
    sudo chmod 644 /home/deploy/.ssh/authorized_keys;
EOF
fi
