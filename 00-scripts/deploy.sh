#/bin/bash
set -e

HOST="root@68.183.221.185 "

# prepare
npm ci
npm test
npm prune --production

# copy
tar --exclude="./.*" -czf - . | ssh $HOST "mkdir -p /root/app; tar zxf - --directory=/root/app"

# systemd
echo "
[Unit]
Description=Cygni Competence Deploy

[Service]
ExecStart=/usr/bin/env npm start
Environment=NODE_ENV=production
Environment=PORT=80
WorkingDirectory=/root/app

[Install]
WantedBy=default.target
" | ssh $HOST "sudo cat > /etc/systemd/system/cygni.service"

ssh $HOST "systemctl daemon-reload; systemctl restart cygni"
