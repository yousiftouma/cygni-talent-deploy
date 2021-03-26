#!/bin/bash
set -e

HOST=$DEPLOY_USER@$SERVER
DEPLOYMENT_NAME=app_$(date +%Y%m%d_%H%M%S)
DEPLOYMENT_DIR=/opt/cygni/$DEPLOYMENT_NAME

tar -czf - src/ package.json package-lock.json | ssh $HOST "mkdir -p $DEPLOYMENT_DIR; tar zxf - --directory=$DEPLOYMENT_DIR"

ssh $HOST "cd $DEPLOYMENT_DIR && npm ci --production"

echo "
[Unit]
Description=Cygni Competence Deploy

[Service]
User=cygni
ExecStart=/usr/bin/env npm start
Environment=NODE_ENV=production
Environment=PORT=8080
Environment=BUILD_NUMBER=${BUILD_NUMBER:-0}
WorkingDirectory=$DEPLOYMENT_DIR

[Install]
WantedBy=multi-user.target
" | ssh $HOST "tee /etc/systemd/system/cygni.service"

ssh $HOST "sudo systemctl daemon-reload && sudo systemctl restart cygni"
