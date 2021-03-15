# CI/CD from scratch

This is a course in Continuous Integration and Continuous Deployment from scracth. That means we are not going to use any off-the-shelf products such as heroku to achieve this. We are going to use a Linux server that we access through ssh. We will automate tasks using bash and run services using systemd.

TODO: server maintenance (crontab?)

## Goals

The goal of this course is to be able to set up simple automated deployments from scratch.

- Managing linux servers through SSH
- Managing linux services using systemd
- Managing application secrets and tokens
- Securing linux servers
- Automating repetitive tasks

## Purpose

The purpose is to gain knowledge of how continuous deployments work under the hood. We will focus on automating all of the tasks. Scripts should be idempotent, meaning we should be able to run them repetetively without changing the result and without errors.

## TODO: Non-goals

TODO: provisioning, ci servers

## Rationale

Why do we need to know this?

...

## Prereqs

TODO: fork repository to your own account

## Step 00 - basic deployment

(Target 45-60 minuter)

Before involving any CI-server, we will make sure we can automate deployment from our own developer machines. The goal is to be able to deploy our application on a fresh VPS without manual intervention.

### Setup host machine

1. Set up non-root user with ssh-login and sudo access

   ```bash
   adduser <USER> --disabled-password --ingroup sudo
   ```

   (tip: provide option `--gecos ""` to skip additional prompts)

1. Enable passwordless sudo for the new user. We need this to be able to execute sudo over ssh.

   ```
   echo "<USER> ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/<USER>
   chmod 440 /etc/sudoers.d/<USER>
   visudo --check
   ```

1. Copy your public ssh key into `/home/<USER>/.ssh/authorized_keys`. This can be done in multiple ways. For example, prepare the file while still logged in at from the host machine:

   ```
   mkdir -p /home/<USER>/.ssh;
   touch /home/<USER>/.ssh/authorized_keys;
   chown -R lenkan /home/<USER>/.ssh;
   chmod 644 /home/<USER>/.ssh/authorized_keys;
   ```

   then

   ```
   cat ~/.ssh/id_rsa.pub | ssh root@<SERVER> "cat - > /home/<USER>/.ssh/authorized_keys"
   ```

1. Make sure you can log in to the host with the new user.

1. Disable ssh login for the root account.

   ```
   echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/setup.conf;
   sudo systemctl restart sshd;
   ```

1. Add a system user for the application

   ```
   sudo adduser --system cygni;
   ```

1. Install dependencies

   ```
   sudo apt update;
   sudo apt install -y ufw nodejs;
   ```

1. Setup firewall rules

   ```
   sudo ufw default deny incoming;
   sudo ufw default allow outgoing;
   sudo ufw allow ssh;
   sudo ufw allow in 8080/tcp;
   sudo ufw --force enable;
   ```

### Deployment

1. Prepare application by installing dependencies, testing etc..

   ```
   npm ci
   npm test
   npm prune --production
   ```

1. Copy application to host machine.

   ```
   DEPLOYMENT_DIR=/opt/cygni-competence-deploy/deploy_$(date +%Y%m%d_%H%M%S)
   tar --exclude="./.*" -czf - . | ssh $HOST "sudo mkdir -p $DEPLOYMENT_DIR; sudo tar zxf - --directory=$DEPLOYMENT_DIR"
   ```

1. Create a systemd service called `cygni`.

   ```
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
   ```

1. Reload the service files. This step is required as long as the service configuration is changed. In our case, we change the service configuration on every deploy.

   ```
   sudo systemctl daemon-reload
   ```

1. Restart the `cygni` service.

   ```
   sudo systemctl restart cygni
   ```

## Step 01 - continuous deployment

In this step, we will start deploying our application from our CI-server whenever changes are pushed to the remote repository. The main issue to overcome here is that the CI-server needs SSH-access to the host machine. We could solve this by somehow uploading our own private SSH-key, but we strongly advise against this. If the key is leaked for some reason, you would have to replace it on every service you use this key. Therefore, we will create a new key specifically for deployment of this application. The public key will be added to the host machines authorized keys, and the private key will be made available to the CI-server for deployment.

### Host machine

1. Create a new SSH key on your machine, we will use this to be able to deploy from a CI-server
1. Copy new key to .ssh/authorized_keys on server machine
1. Create known_hosts file from host machine

### CI-server

1. Upload keys and known hosts as github secrets
1. Create a new basic github action that imports secrets and executes the deploy script.

### Deployment

1. Write key and hosts file to file from environment
1. Specify key file and hosts when using connecting to host machine

## Continue...

<!-- - Step XX - non-root - create non-root user that runs application -->

- Step XX - dockerize - dockerize the application to make it more portable (needs a purpose? maybe db?)
- Step XX - reverse-proxy - setup reverse proxy HAProxy/Nginx/Traefik
- Step XX - certificate - letsencrypt
- Step XX - multiple environments - test/staging/prod
  - test master
  - tag -> deploy staging
  - manuellt -> deploy tag (måste finnas en tag som är deployad på stage)
  - samma maskin
- Step XX - rensa bort gamla deployments
