#/bin/bash
set -e

# ssh
if test -f .ssh/deploy; then
    echo ".ssh/deploy exists"
else
    mkdir -p .ssh/
    echo "$SSH_PRIVATE_KEY" > .ssh/deploy
    sudo chmod 600 .ssh/deploy
    echo "$SSH_KNOWN_HOSTS" > .ssh/known_hosts
fi

HOST="-i ./.ssh/deploy -o UserKnownHostsFile=./.ssh/known_hosts root@68.183.221.185 "
DEPLOYMENT_DIR=/root/app_$(date +%Y%m%d_%H%M%S)

# prepare
npm ci
npm test
npm prune --production

# copy
tar --exclude="./.*" -czf - . | ssh $host "mkdir $deployment_dir; tar zxf - --directory=$deployment_dir"

# systemd
echo "
[Unit]
Description=Cygni Competence Deploy

[Service]
ExecStart=/usr/bin/env npm start
Environment=NODE_ENV=production
Environment=PORT=80
WorkingDirectory=$DEPLOYMENT_DIR

[Install]
WantedBy=default.target
" | ssh $HOST "sudo cat > /etc/systemd/system/cygni.service"

ssh $HOST "systemctl daemon-reload; systemctl restart cygni"
