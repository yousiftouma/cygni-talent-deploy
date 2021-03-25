# CI/CD from scratch

This is a course in Continuous Integration and Continuous Deployment from scracth. That means we are not going to use any off-the-shelf products such as heroku to achieve this. We are going to use a Linux server that we access through ssh. We will automate tasks using bash and run services using systemd.

## Goals

The goal of this course is to be able to set up simple automated deployments from scratch.

- Managing linux servers through SSH
- Managing linux services using systemd
- Managing application secrets and tokens
- Securing linux servers
- Automating repetitive tasks

## Purpose

The purpose is to gain knowledge of how continuous deployments work under the hood. We will focus on automating all of the tasks. Scripts should be idempotent, meaning we should be able to run them repetetively without changing the result and without errors.

## Agenda

- Presentation CI/CD
- Walk through step 00
- Do step 00 (X min)

- Walk through step 01
- Do step 01 (Y min)

- Step 02 - reverse-proxy - HAProxy/Nginx/Traefik

  - What is HAProxy (presentation)
  - Install haproxy
  - Follow guide to setup simple http proxy to TODO: find guide or give a tip on google search
  - ufw disable 8080

- Step 03 - support different environments - test/staging/prod

  - modify deploy script to support different deployment directories and systemd services
  - /opt/cygni-talent-deploy_test/app_date -> 8081
  - /opt/cygni-talent-deploy_prod/app_date -> 8080
  - Kanske <SERVER>:80/\_test -> 8081
  - Kanske <SERVER>:80 -> 8080

- TODO: Script för att rätta allas servrar
  - Rätt portar öppna
  - Inte ssh:a in som root

## TODO: Non-goals

TODO: provisioning, ci servers

## Rationale

Why do we need to know this?

...

## Pre requisites

- Fork this repository to your own GitHub account
- `ssh` client installed on your machine
- Terminal installed
  - Windows WSL
  -
- node v14+ with npm
- systemd: https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files

TODO(emil): Add list and links

<!-- Dom här linuxkommandona behöver du förstå och kunna göra lokalt:
Lokalt
ssh
ssh-copy-id
ssh-keygen
tar
echo
scp

På maskinen
|
Tee
Mkdir
Chmod
Systemctl
curl
Sudo
Touch
Chown -->

## Step 00 - basic deployment

(Target 45-60 minuter)

Before involving any CI-server, we will make sure we can automate deployment from our own developer machines. The goal is to be able to deploy our application on a fresh VPS without manual intervention.

### Setup admin account on server

1. Set up a variable containing your host servers IP adress, this will make it easier to copy-paste commands later on.

   ```bash
   export SERVER=<SERVER-IP>
   ```

1. Create an SSH-key that we will use for our new admin account.

   TODO: Enter a passphrase

   ```bash
   mkdir -p .ssh
   ssh-keyscan $SERVER > .ssh/known_hosts
   ssh-keygen -f .ssh/admin
   ```

1. Create a new SSH config file that we will use during the exercise.

   ```bash
   echo "
   Host cygni
      HostName $SERVER
      UserKnownHostsFile $(realpath ./.ssh/known_hosts)

   Match user root
      PasswordAuthentication yes
      IdentityFile $(realpath ./.ssh/admin)

   Match user admin
      IdentityFile $(realpath ./.ssh/admin)

   Match user deploy
      IdentityFile $(realpath ./.ssh/deploy)
   " > ./.ssh/config
   ```

1. Copy the admin key to enable ssh login using the ssh key. This will save us having to type the root password on each access during our setup.

   ```bash
   ssh-copy-id -i .ssh/admin.pub -F .ssh/config root@cygni
   ```

1. Before creating the new admin user, copy the same public key to server.

   ```bash
   scp -F .ssh/config .ssh/admin.pub root@cygni:/tmp/admin.pub
   ```

1. Connect to the server and create the new user account

   ```bash
   ssh -t -F .ssh/config root@cygni "\
      adduser admin --ingroup sudo --gecos \"\" && \
      mkdir -p /home/admin/.ssh && \
      mv /tmp/admin.pub /home/admin/.ssh/authorized_keys && \
      chown admin /home/admin/.ssh && \
      chmod 644 /home/admin/.ssh/authorized_keys"
   ```

1. After this, ssh access should be enabled for the admin user. Try it out:

   ```bash
   ssh -t -F .ssh/config admin@cygni "sudo -l"
   ```

1. Since we now have an admin account with sudo priviliges, we should disable root login through ssh.

   ```bash
   echo "
   PermitRootLogin no
   PasswordAuthentication no
   " | ssh -F .ssh/config admin@cygni "cat - > /tmp/sshd_config"
   ```

   ```bash
   ssh -t -F .ssh/config admin@cygni "sudo mv /tmp/sshd_config /etc/ssh/sshd_config.d/setup.conf && sudo systemctl restart sshd"
   ```

1. Make sure you cannot login as root anymore. You should get an error similar to `root@xx.xx.xx.xx: Permission denied (publickey).`

   ```bash
   ssh -F .ssh/config root@cygni exit
   ```

### Setup dependencies and firewall

1. Install dependencies

   ```bash
   ssh -t -F .ssh/config admin@cygni "\
      curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash - && \
      sudo apt update && \
      sudo apt install -y ufw nodejs"
   ```

1. Setup firewall rules

   ```bash
   ssh -t -F .ssh/config admin@cygni "\
      sudo ufw default deny incoming && \
      sudo ufw default allow outgoing && \
      sudo ufw allow ssh && \
      sudo ufw allow http && \
      sudo ufw allow in 8080/tcp && \
      sudo ufw --force enable"
   ```

### Create system user

1. Create a system user that we will use to run the service

   ```bash
   ssh -t -F .ssh/config admin@cygni "sudo adduser --system cygni"
   ```

### Deployment

1. Prepare application by installing dependencies, testing etc..

   ```bash
   npm ci
   npm test
   npm prune --production
   ```

1. Copy application to host machine.

   ```bash
   DEPLOYMENT_NAME=app_$(date +%Y%m%d_%H%M%S)
   DEPLOYMENT_DIR=/opt/cygni-competence-deploy/$DEPLOYMENT_NAME

   tar -czf tmp_$DEPLOYMENT_NAME.tar.gz src/ node_modules/ package.json

   scp -F .ssh/config tmp_$DEPLOYMENT_NAME.tar.gz admin@cygni:/tmp/$DEPLOYMENT_NAME.tar.gz

   ssh -t -F .ssh/config admin@cygni "\
      sudo mkdir -p $DEPLOYMENT_DIR && \
      sudo tar zxf /tmp/$DEPLOYMENT_NAME.tar.gz --directory=$DEPLOYMENT_DIR && \
      rm /tmp/$DEPLOYMENT_NAME.tar.gz"
   ```

1. Create/edit the systemd service called `cygni`.

   ```bash
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
   " > tmp_cygni.service

   scp -F .ssh/config tmp_cygni.service admin@cygni:/tmp/cygni.service
   ssh -t -F .ssh/config admin@cygni "sudo mv /tmp/cygni.service /etc/systemd/system/cygni.service"
   ```

1. Reload the unit and restart the service.

   ```bash
   ssh -t -F .ssh/config admin@cygni "sudo systemctl daemon-reload && sudo systemctl restart cygni"
   ```

1. The server should be up and running now. Try it out

   ```bash
   curl $SERVER:8080
   ```

## Step 01 - continuous deployment

### Create deploy user

1. Create a new ssh key to use for deployments

   ```bash
   ssh-keygen -f .ssh/deploy
   ```

1. Copy the public key to the server

   ```bash
   scp -F .ssh/config .ssh/deploy.pub admin@cygni:/tmp/deploy.pub
   ```

1. Create the user

   ```bash
   ssh -t -F .ssh/config admin@cygni "\
      sudo addgroup deployers && \
      sudo adduser deploy --disabled-password --ingroup deployers --gecos \"\" && \
      sudo mkdir -p /home/deploy/.ssh && \
      sudo mv /tmp/deploy.pub /home/deploy/.ssh/authorized_keys && \
      sudo chown -R deploy /home/deploy/.ssh && \
      sudo chmod 644 /home/deploy/.ssh/authorized_keys"
   ```

1. Now, you can login as the user `deploy` on the server. Verify by

   ```bash
   ssh -F .ssh/config deploy@cygni exit
   echo $?
   ```

1. Make sure the deploy user has sufficient rights to create and edit and start a systemd service called `cygni`. This will be done by assigning ownership of the systemd unit file and the directory we will use to store our app deployments.

   ```bash
   ssh -t -F .ssh/config admin@cygni "\
      sudo touch /etc/systemd/system/cygni.service && \
      sudo chown root:deployers /etc/systemd/system/cygni.service && \
      sudo chmod 664 /etc/systemd/system/cygni.service && \
      sudo mkdir -p /opt/cygni-competence-deploy && \
      sudo chown root:deployers /opt/cygni-competence-deploy && \
      sudo chmod 755 /opt/cygni-competence-deploy"
   ```

1. Finally, the deployers group need to have passwordless permissions to reload the systemd unit and restart the service.

   ```bash
   DEPLOY_SUDOERS="%deployers ALL=NOPASSWD:/bin/systemctl daemon-reload, /bin/systemctl restart cygni"
   ssh -t -F .ssh/config admin@cygni "
      echo \"$DEPLOY_SUDOERS\" | sudo visudo --check -f -
      echo \"$DEPLOY_SUDOERS\" | sudo EDITOR=\"tee\" visudo -f /etc/sudoers.d/10-setup-deploy"
   ```

### Deployment

The script in [deploy.sh](./scripts/deploy.sh) is essentially the same steps as performed in the basic deployment from local machine. But it uses the `deploy` user for deploying the application.

```bash
#!/bin/bash
set -e

DEPLOYMENT_DIR=/opt/cygni-competence-deploy/app_$(date +%Y%m%d_%H%M%S)

if test -f .ssh/config; then
    echo ".ssh/config already exists"
else
    echo ".ssh/config does not exist, writing from env"

    mkdir -p .ssh
    echo "$SSH_PRIVATE_KEY" > ./.ssh/deploy
    echo "$SSH_KNOWN_HOSTS" > ./.ssh/known_hosts
    chmod 600 .ssh/deploy

    echo "Host cygni
    HostName $SERVER
    IdentityFile $(realpath ./.ssh/deploy)
    UserKnownHostsFile $(realpath ./.ssh/known_hosts)
    " | tee ./.ssh/config
fi

# prepare
npm ci
npm test
npm prune --production

# copy
tar -czf - src/ node_modules/ package.json | ssh -F .ssh/config deploy@cygni "mkdir -p $DEPLOYMENT_DIR; tar zxf - --directory=$DEPLOYMENT_DIR"

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
```

1. Try to run the script once locally to make sure it works.

   ```bash
   ./scripts/deploy.sh
   ```

   (Tip: to actually see that a new version has been deployed, you can edit `index.js`)

1. Upload .ssh/deploy and .ssh/known_hosts as github secrets.
   Settings -> Secrets -> Environment Secrets

   Select appropriate names for the secrets such as `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS`.

1. Create a new basic github action that imports secrets and executes the deploy script.

   ```yaml
   - name: Deploy
     run: ./scripts/deploy.sh
     shell: bash
     env:
       SSH_PRIVATE_KEY: ${{secrets.SSH_PRIVATE_KEY}}
       SSH_KNOWN_HOSTS: ${{secrets.SSH_KNOWN_HOSTS}}
       SERVER: "68.183.221.185"
   ```

## Continue...

- cert ssl-termination
- zero downtime deployment
- Step XX - multiple environments - test/staging/prod
- test master
- tag -> deploy staging
- manuellt -> deploy tag (måste finnas en tag som är deployad på stage)
- samma maskin
- Step XX - rensa bort gamla deployments

- t.ex. max 10 gamla deployments, titta på cron

- TODO: ssh profiler, istället för att lägga i .ssh
- TODO: deploy ska bara kunna köra vissa kommandon.
- TODO: hitta en guide för nginx som rev-proxy
- TODO: Förtydliga vad som körs på server/local

- TODO: prereqs
- forka repo (dubbelkolla att GA funkar)
- TODO: presentera saker
- CI/CD
- översikt/målbild
- vad kursen inte tar hand om
- race conditions
- provisionering
- Specifika CI servers
- systemd
- ssh
- sudo
- förklara script
