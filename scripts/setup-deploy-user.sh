#!/bin/bash
set -e

mkdir -p .ssh

DEPLOY_SUDOERS="%deployers ALL=NOPASSWD:/bin/systemctl daemon-reload, /bin/systemctl restart cygni"

# Create deployment user with ssh access
scp -F .ssh/config .ssh/deploy.pub admin@cygni:/tmp/deploy.pub
ssh -t -F .ssh/config admin@cygni "
    set -e

    id -u deploy && sudo deluser deploy && sudo rm -rf /home/deploy
    getent group deployers && sudo delgroup deployers

    echo \"Creating user\"
    sudo addgroup deployers
    sudo adduser deploy --disabled-password --ingroup deployers --gecos \"\"

    echo \"Create service user cygni\"
    id -u cygni || sudo adduser --system cygni

    echo \"Setting up ssh access\"
    sudo mkdir -p /home/deploy/.ssh
    sudo mv /tmp/deploy.pub /home/deploy/.ssh/authorized_keys
    sudo chown -R deploy /home/deploy/.ssh
    sudo chmod 644 /home/deploy/.ssh/authorized_keys

    echo \"Setting up cygni.service rights\"
    sudo touch /etc/systemd/system/cygni.service
    sudo chown deploy:deployers /etc/systemd/system/cygni.service
    sudo chmod 664 /etc/systemd/system/cygni.service

    sudo mkdir -p /opt/cygni-competence-deploy
    sudo chown deploy:deployers /opt/cygni-competence-deploy

    echo \"$DEPLOY_SUDOERS\" | sudo visudo --check -f -
    echo \"$DEPLOY_SUDOERS\" | sudo EDITOR=\"tee\" visudo -f /etc/sudoers.d/10-setup-deploy
"
