#/bin/bash
set -e

HOST="lenkan@68.183.221.185"
DEPLOYMENT_DIR=/opt/cygni-competence-deploy/app_$(date +%Y%m%d_%H%M%S)

# prepare
npm ci
npm test
npm prune --production

# copy
tar --exclude="./.*" -czf - . | ssh $HOST "sudo mkdir -p $DEPLOYMENT_DIR; sudo tar zxf - --directory=$DEPLOYMENT_DIR"

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
" | ssh $HOST "sudo tee /etc/systemd/system/cygni.service > /dev/null"

ssh $HOST "sudo systemctl daemon-reload; sudo systemctl restart cygni"
