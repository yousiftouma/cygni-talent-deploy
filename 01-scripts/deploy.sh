#/bin/bash
set -e

if !test -f .ssh/deploy; then
    echo ".ssh/deploy does not exist"
    exit 1;
fi

SSH_OPTS="-i ./.ssh/deploy -o UserKnownHostsFile=./.ssh/known_hosts"
SERVER=68.183.221.185
DEPLOYMENT_DIR=/opt/cygni-competence-deploy/app_$(date +%Y%m%d_%H%M%S)

# prepare
npm ci
npm test
npm prune --production

# copy
tar --exclude="./.*" -czf - . | ssh $SSH_OPTS deploy@$SERVER "sudo mkdir -p $DEPLOYMENT_DIR; sudo tar zxf - --directory=$DEPLOYMENT_DIR"

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
" | ssh $SSH_OPTS deploy@$SERVER "sudo tee /etc/systemd/system/cygni.service > /dev/null"

ssh $SSH_OPTS deploy@$SERVER "sudo systemctl daemon-reload; sudo systemctl restart cygni"
