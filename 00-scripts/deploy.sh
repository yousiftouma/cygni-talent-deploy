#/bin/bash
set -e

HOST="root@68.183.221.185 "
DEPLOYMENT_DIR=/root/app_$(date +%Y%m%d_%H%M%S)

# prepare
npm ci
npm test
npm prune --production

# copy
tar --exclude="./.*" -czf - . | ssh $host "mkdir $DEPLOYMENT_DIR; tar zxf - --directory=$DEPLOYMENT_DIR"

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
