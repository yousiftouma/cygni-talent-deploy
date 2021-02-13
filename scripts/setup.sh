#/bin/bash
set -e
SERVER=68.183.221.185
HOST=root@$SERVER

# setup ssh
if test -f .ssh/deploy; then
    echo ".ssh/deploy already exists"
else
    mkdir -p .ssh
    ssh-keygen -f .ssh/deploy -t rsa -b 4096
    ssh-keyscan $SERVER > .ssh/known_hosts
    echo ".ssh/deploy created"
fi

if ssh -q -i .ssh/deploy $HOST exit; then
    echo ".ssh/deploy connection accepted"
else
    echo "copy .ssh/deploy to host server"
    cat .ssh/deploy.pub | ssh $HOST "sudo cat >> /root/.ssh/authorized_keys"
fi

ssh $HOST "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; apt update; apt install -y ufw nodejs git"
ssh $HOST "ufw default deny incoming; ufw default allow outgoing; ufw allow ssh; ufw allow http; ufw --force enable"
