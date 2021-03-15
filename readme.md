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
   sudo apt install -y ufw nodejs npm;
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

In this step, we will start to deploy our application from a CI-server when code changes are pushed to a remote repository. The main issue to overcome here is that the CI-server needs SSH-access to the host machine.

We will create a new SSH-key locally specifically for this purpose. This SSH-key will be used on our CI-server to access the host machine.

### Host machine

**Note: all command snippets assume that the current working directory is the repository root**

1. Create a new SSH key on your machine. For now, we will simply store it a directory called `.ssh` relative to the repository directory. Make sure the ssh keys are ignored by git.

   ```
   mkdir -p .ssh
   ssh-keygen -f .ssh/deploy -t rsa -b 4096
   ```

1. Retrieve the public keys from the server and save to a file.

   ```
   ssh-keyscan <SERVER> > .ssh/known_hosts
   ```

1. Create a new user called `deploy` on the host.

   You can follow the same instructions as when creating the admin user.

   **TODO** create an appropriate limited sudoers file

1. Copy .ssh/deploy.pub to /home/deploy/authorized_keys on the host machine.

### Deployment

We need to modify our deploy script so that it uses the provided ssh-keys. This can be done with the `-i` and `-o` flags to ssh.

For example:

```
SSH_OPTS="-i ./.ssh/deploy -o UserKnownHostsFile=./.ssh/known_hosts"

ssh $SSH_OPTS deploy@<SERVER> "<cmd>"
```

### CI-server

1. Upload .ssh/deploy and .ssh/known_hosts as github secrets.
   Settings -> Secrets -> Environment Secrets

   Select appropriate names for the secrets such as `SSH_PRIVATE_KEY` and `SSH_KNOWN_HOSTS`.

1. Create a new basic github action that imports secrets and executes the deploy script.

   The first step needs to grab the secrets and write them to the file system.

   ```
   - name: Secrets
     run: |
        mkdir -p .ssh
        echo "$SSH_PRIVATE_KEY" > .ssh/deploy
        sudo chmod 600 .ssh/deploy
        echo "$SSH_KNOWN_HOSTS" > .ssh/known_hosts
     shell: bash
     env:
        SSH_PRIVATE_KEY: ${{secrets.SSH_PRIVATE_KEY}}
        SSH_KNOWN_HOSTS: ${{secrets.SSH_KNOWN_HOSTS}}
   ```

   The second step can simply execute the script.

   ```
   - name: Deploy
     run: ./01-scripts/deploy.sh
     shell: bash
   ```

## Continue...

- Step XX - dockerize - dockerize the application to make it more portable (needs a purpose? maybe db?)
- Step XX - reverse-proxy - setup reverse proxy HAProxy/Nginx/Traefik
- Step XX - certificate - letsencrypt
- Step XX - multiple environments - test/staging/prod
  - test master
  - tag -> deploy staging
  - manuellt -> deploy tag (måste finnas en tag som är deployad på stage)
  - samma maskin
- Step XX - rensa bort gamla deployments
