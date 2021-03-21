#!/bin/bash
set -e

DEPLOYMENT_DIR=/opt/cygni-competence-deploy/app_$(date +%Y%m%d_%H%M%S)

if test -f .ssh/config; then
    echo ".ssh/config already exists"
else
    echo ".ssh/config does not exist, writing from env"

    mkdir -p .ssh
    echo $SSH_PRIVATE_KEY > ./.ssh/deploy
    echo $SSH_KNOWN_HOSTS > ./.ssh/known_hosts

    echo "Host cygni
        HostName $SERVER
        IdentityFile $(realpath ./.ssh/deploy)
        UserKnownHostsFile $(realpath ./.ssh/known_hosts)
    " > ./.ssh/config
fi

# prepare
npm ci
npm test
npm prune --production

# copy
tar --exclude="./.*" -czf - . | ssh -F .ssh/config deploy@cygni "mkdir -p $DEPLOYMENT_DIR; tar zxf - --directory=$DEPLOYMENT_DIR"

# systemd
echo "
[Unit]
Description=Cygni Competence Deploy

[Service]
User=cygni
ExecStart=/usr/bin/env npm start
Environment=NODE_ENV=production
Environment=PORT=8080
WorkingDirectory=$DEPLOYMENT_DIR

[Install]
WantedBy=multi-user.target
" | ssh -F .ssh/config deploy@cygni "tee /etc/systemd/system/cygni.service > /dev/null"

ssh -F .ssh/config deploy@cygni "sudo systemctl daemon-reload; sudo systemctl restart cygni"
