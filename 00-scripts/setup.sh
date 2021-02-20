#/bin/bash
set -e
SERVER=68.183.221.185
HOST=root@$SERVER

ssh $HOST "curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -; apt update; apt install -y ufw nodejs"
ssh $HOST "ufw default deny incoming; ufw default allow outgoing; ufw allow ssh; ufw allow http; ufw --force enable"
