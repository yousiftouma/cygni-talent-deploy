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
  - Follow guide to set up simple http proxy to TODO: find guide or give a tip on google search
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

# Exercises

## Terminology

- local machine - your own computer
- server - the server that is hosting the application
- build server - the server that is test, building and deploy the application
- admin - the user account with administrative tasks, should be personal

## Tips and trix

### Reading files on the server

You can use `cat` or `less` to read files on the server.

`cat` will print the file to stdout.

```
cat /path/to/file
```

`less` is a program that enables you to scroll through files and search among other things

```
less /path/to/file
```

### Writing files on server

Editing files on the remote server can be a bit tricky unless you are familiar with linux tools such as `vi`, `nano` and `tee` among others.

`vi` and `nano` are editors and are the most straight forward way to edit a file in place.

```
vi /path/to/file
```

You can use `tee` on the server to write files from stdin.

```
echo "Some content
with newlines" | tee /path/to/file
```

You can also pipe stdin through `ssh` from your local machine.

```
echo "Some content" | ssh user@host "tee /path/to/remotefile"
```

In some cases, it is easier to write to files locally and copy them to the remote server using `scp`:

```
scp /path/to/localfile user@host:/path/to/remotefile
```

## Step 01 - Log in to server

Initially, you will be able to log in to the server as `root` using the provided password. It can be convenient to add an entry for your server in your `~/.ssh/config` file. Check `man ssh_config` for more information.

For example:

```
Host cygni-deploy
   HostName <SERVER-IP>
```

will allow us to do

```
ssh <USER>@cygni-deploy
```

instead of

```
ssh <USER>@<SERVER-IP>
```

1. On your local machine, add an entry for your server in ~/.ssh/config.

1. On your local machine, log in to the server as root. You will be prompted for the root password.

   ```
   ssh root@cygni-deploy
   ```

## Step 02 - Create admin user

It is widely considered bad practice to directly use root for administrative tasks on linux servers. The root user has permissions to do anything without restrictions. The recommended approach is to create an admin user that has priviliges to run commands _as_ root using `sudo`.

In most cases, admin accounts should be personal. They are then given administrative powers by belonging to a certain group. We will use the pre-defined group `sudo` for this. By default, members of `sudo` has permissions to run any command as any user as long as the user can provide their password.

1. On the server, create a new user with default settings.

   The simplest way is to use the `adduser`. See `man adduser`. Make sure you remember the password provided.

1. On the server, add the user to the group `sudo`. See `man adduser`.

1. On the server, check which groups a user belongs to using the command.

   ```
   groups <USERNAME>
   ```

   The expected output is

   ```
   <USERNAME>: <USERGROUP> sudo
   ```

   where `<USERGROUP>` is a group with the same name as the user that is created by default by `adduser` unless otherwise specified.

1. On the server, check that a /home directory for the user has been created.

   ```
   ls -la /home
   drwxr-xr-x  5 root        root         4096 Mar 26 12:00 .
   drwxr-xr-x 20 root        root         4096 Mar 26 12:00 ..
   drwxr-xr-x  7 <USERNAME>  <USERGROUP>  4096 Mar 26 12:00 <USERNAME>
   ```

   `<USERNAME>` and `<USERGROUP>` should be the owners of the `/home/<USERNAME>` directory. If not, something has gone wrong.

## Step 03 - Set up public key authentication

You will be able to log in to the server as the admin user using your password. However, it is easier and more secure to use public key authentication. It will enable you to log in to the server without providing your password.

1. On your local machine, create a new ssh key using the tool `ssh-keygen`.

   If you already have an SSH-key that you can use, you can skip this step. Otherwise, you can use the default options when prompted. If you want to, you can choose a different filename or location for your key.

   **NOTE** Do not overwrite any of your already existing keys! The program will warn you before that happens.

1. On your local machine, copy your public SSH-key to the server to allow admin login using SSH.

   The simplest way is to use the utility `ssh-copy-id`. Check `man ssh-copy-id` for more information. You will be prompted for the admin password on the server.

1. On your local machine, log in as the admin user on the server using your SSH key. The following command should work without being prompted for the user password.

   ```
   ssh <USERNAME>@cygni-deploy
   ```

   If you can not log in, try to find out what is going wrong.

   1. Add `--verbose` to the ssh command, this will print debug logs.
   1. Log in as root on the server and check the logs for the SSH server `journalctl --follow --identifier sshd`.

   It is important that you do not move on until you have successfully logged in as the new admin user.

1. On the server, verify the contents of `/home/<USERNAME>/.ssh/authorized_keys`. It should contain the public key (or keys) that you copied using `ssh-copy-id`. The contents of this file is what determines which keys you can use to log on as the admin user.

## Step 04 - Secure SSH

Currently, both root and the admin user are allowed to login to the server using their password. This is a potential security threat as there is only one factor that protects you from giving someone full access to the server. There are many different ways to secure your server and there are trade offs to consider in terms of convenience and security.

You are going to disable password authentication as a login method for all users and disable root login completely. Effectively, you have added one extra layer of security. To gain admnistrative powers on the server, an attacker would need both your private SSH key and your admin password.

The SSH server settings are defined in `/etc/ssh/sshd_config`. Files ending in `*.conf` in the directory `/etc/ssh/sshd_config.d/` are included by default in Ubuntu. See `man sshd_config` on the server for more information.

1. On the server, edit/create `/etc/ssh/sshd_config.d/00-setup.conf`, add these lines:

   ```
   PermitRootLogin no
   PasswordAuthentication no
   ```

1. On the server, restart the SSH server to pick up the changes.

   ```
   sudo systemctl restart sshd
   ```

1. On your local machine, make sure that you cannot log in as root on the server.

## Step 05 - Firewall

It is a good idea to set up a firewall to control incoming and outgoing traffic. Ubuntu comes with `ufw`, see `man ufw` for more information.

Here is a good resource on `ufw` from Digital Ocean: https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-20-04

**Important**: make sure that you do not block SSH-traffic, you can potentially lock yourself out of the server.

1. On the server, make sure you have UFW installed

   ```bash
   sudo apt update
   sudo apt install ufw
   ```

1. On the server, set up rules, see `man ufw` or the Digital Ocean tutorial for further instructions.

   - Deny all incoming traffic except for
     - SSH (port 22)
     - Port 8080, we will use this for our application
   - Allow outgoing traffic

1. On the server, check the status of ufw `sudo ufw status numbered`.

   ```
   Status: active

        To                         Action      From
        --                         ------      ----
   [ 1] 22/tcp                     ALLOW IN    Anywhere
   [ 2] 8080/tcp                   ALLOW IN    Anywhere
   [ 3] 22/tcp (v6)                ALLOW IN    Anywhere (v6)
   [ 4] 8080/tcp (v6)              ALLOW IN    Anywhere (v6)
   ```

1. On your local machine, test the firewall using `telnet`.

   - For _denied_ ports, the connection will timeout.
   - For _allowed_ ports, a connection should be opened.
   - If you chose _reject_ instead if _deny_, you will get a "Connection refused" error.

## Step 06 - Dependencies

Our application needs node.js installed to run. Install the latest LTS version. See https://nodejs.org/en/download/package-manager/

1. On the server, install node.js

1. On the server, make sure `npm` and `node` is available.

   ```
   node -v
   v14.XX.Y
   ```

   ```
   npm -v
   6.XX.Y
   ```

## Step 07 - Service

Finally time to run the app on the server.

1. On your local machine, create a tarball of `src/`, `package.json` and `package-lock.json`. See `man tar`.

1. On your local machine, copy the tarball to the server. See `man scp`. Place the files on the server in your users home directory or in `/tmp`.

1. On the server, unpackage the the tarball to an appropriate location. We suggest to place it in `/opt/cygni/app`.

1. On the server, if not already there, navigate to the directory where the tarball was unpackaged and install any dependencies using `npm ci --production`.

1. On the server, start the service `npm start`.

1. On your local machine, test the service using curl.

   ```
   curl $SERVER:8080
   ```

   You should receive a "Hello World!" reply. If not, use error messages to trace back where something could have gone wrong. Ask for help if needed.

1. On the server, stop the application.

## Step 08 - Deployment

In the previous step, we ran the application in the foreground. The application should run in the background so that it can continue to run even after we log out from the server. We can achieve this by running it using `systemd`. `systemd` is a system and service manager for linux. It is configured by adding unit files in the `/etc/systemd` directory. The tool `systemctl` is used to control `systemd`. See `man systemd` for more information.

1. On the server, create a new system user using `adduser --system cygni`. This will create an unprivileged, passwordless and groupless user that we will use to run our application on the server.

1. On the server, create a new systemd service by creating a file `/etc/systemd/cygni.service`.

   ```
   [Unit]
   Description=Cygni Talent Deploy

   [Service]
   User=cygni
   ExecStart=/usr/bin/env npm start
   Environment=NODE_ENV=production
   Environment=PORT=8080
   WorkingDirectory=/opt/cygni/app

   [Install]
   WantedBy=multi-user.target
   ```

1. On the server, start the service using `systemctl`. See `man systemctl` for instructions.

1. On your local machine, test the service using curl.

   ```
   curl $SERVER:8080
   ```

1. On the server, you can follow the logs using `sudo journalctl --follow --unit cygni`

## Step 09 - Scripted deployment

Next step is to automate the tasks in the previous step. The script [`./scripts/deploy.sh`](./scripts/deploy.sh) is performing the same tasks. However, if you try to run it now, you will get some permissions errors. We will solve this by adding a new group called `deployers` for more granular permission control. Users in this group should have sufficient permissions for deploying our application, but not more!

The `deployers` group will have group ownership and write permissions to the `/opt/cygni` directory and the `/etc/systemd/cygni.service`. In addition, they will have passwordless access to the commands to restart the `cygni` service.

1. On the server, add a new group called `deployers`. See `man addgroup`.

1. On the server, add your admin account to the `deployers` group.

   Verify using `groups` command

   ```
   groups <USERNAME>
   <USERNAME>: <USERGROUP> sudo deployers
   ```

1. On the server, recursively change the group ownership of `/opt/cygni` to `deployers`.

1. On the server, change the permissions to allow the deployers group to read, write and traverse the `/opt/cygni` directory.

   Expected permissions are as follows:

   ```
   ls -la /opt
   total 12
   drwxr-xr-x  3 root root      4096 Mar 26 22:03 .
   drwxr-xr-x 20 root root      4096 Mar  9 18:02 ..
   drwxrwxr-x 24 root deployers 4096 Mar 28 11:51 cygni
   ```

1. On the server, change the group ownership on the cygni service unit file `/etc/systemd/cygni.service` to `deployers`.

1. On the server, change the permissions of `/etc/systemd/cygni.service` to be writable by members of the `deployers` group.

   Expected permissions are as follows:

   ```
   ls -la /etc/systemd/system/cygni.service
   -rw-rw-r-- 1 root deployers 267 Mar 28 11:51 /etc/systemd/system/cygni.service
   ```

1. On the server, create a new sudoers using `sudo visudo -f /etc/sudoers.d/setup-deployers`. See `man visudo` and `man sudoers` for mor information.

   Enter the following row

   ```
   %deployers ALL=NOPASSWD:/bin/systemctl daemon-reload, /bin/systemctl restart cygni
   ```

   **important** never edit a sudoers file manually. visudo guarantees that no malformated files are saved. If the sudoers file is broken, `sudo` will not work and there might not be a way to correct the file without `sudo`.

   **tip** you can force visudo to use a different editor by setting the environment variable EDITOR before running visudo. (EDITOR=vi visudo -f /etc/sudoers.d/setup-deployers)

1. On your local machine, run the script `./scripts/deploy.sh`.

   Set the environment variable `DEPLOY_USER` to specify the username of your admin user on the server. Make sure that no interactive password prompts appear.

   ```
   export DEPLOY_USER=<USERNAME>
   ./scripts/deploy.sh
   ```

1. On the server, check the logs in `journalctl`, you should be able to see that the server was restarted.

1. On your local machine, make some edits to the Hello World reply in `src/index.js`, then rerun the deploy script.

1. On your local machine, curl the application to verify that the deployment succeeded.

## Step 10 - Set up CI

Now it is time to focus on the continuous integration part of the exercise. In this step we will create a new github action.

1. Create a new github action, follow these links on your repository page

   Actions -> New workflow -> "Skip this and set up a workflow yourself"

   This will generate a skeleton workflow file for you. Walk through the document and try to understand its structure.

1. Add a step after the checkout step that sets up node.js on the build machine

   ```
   - name: Set up node
     uses: actions/setup-node@v2
     with:
        node-version: "14"
   ```

1. Add a step for running the unit tests using the command `npm test`

1. Save and commit the file to master. Now you should be able to see the workflow under the "Actions" tab. If you kept the "workflow_dispatch:" property from the skeleton, you can manually trigger the workflow from the github GUI as well. Move on once you have made sure that the workflow works as expected.

## Step 11 - Set up static code analysis

TODO: eslint and stuff

## Step 12 - Github Actions deployment

Time to enable github to deploy our application. We need to create a new user on the server called `github` which our github action will use when logging in to the server. This user will be in group `deployers`, which we've already made sure has sufficient permissions to deploy the application.

1. On the server, add a new user called `github` make sure to use `--disabled-password` flag to skip password set up for this user.

1. On the server, add the `github` user to the group `deployers`.

1. On your local machine, create a new SSH-key, name it to something appropriate, like `cygni_id_github` and store it somewhere temporarily. You should delete it from your machine as soon as you have uploaded it to github.

   ```
   ssh-keygen -f cygni_id_github
   ```

1. On your local machine, scan the server for its public keys and save it to a known_hosts file next to the keys generated in the previous step. We will upload this to github as well to verify that the servers host keys are not changed.

   ```
   ssh-keyscan $SERVER > cygni_known_hosts
   ```

1. Copy the public key (`cygni_id_github.pub`), from your local machine to the server at `/home/github/.ssh/authorized_keys`.

   Remember to set the correct ownership and permissions. See Step 03.

   ```
   ls -la /home/github/.ssh/
   total 12
   drwx------ 2 github github 4096 Mar 26 23:27 .
   drwxr-xr-x 5 github github 4096 Mar 26 23:48 ..
   -rw------- 1 github github  568 Mar 26 23:27 authorized_keys
   ```

1. On your local machine, test the SSH connection

   ```
   ssh -i ./cygni_id_github github@cygni-deploy
   ```

1. Upload the key and known hosts as github secrets on your own fork.

   Settings -> Secrets -> New Repository Secret

   Give the secrets approriate names such as `SSH_KNOWN_HOSTS` and `SSH_PRIVATE_KEY`.

1. Add step "set up SSH"

   - Set up SSH keys

     ```
     - name: Set up ssh
       run: |
         mkdir -p ~/.ssh
         echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
         echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
         chmod 600 ~/.ssh/id_rsa
       env:
         SSH_PRIVATE_KEY: ${{secrets.SSH_PRIVATE_KEY}}
         SSH_KNOWN_HOSTS: ${{secrets.SSH_KNOWN_HOSTS}}
     ```

1. Add step "deploy"

   - Set up deploy script

     ```
     - name: Deploy
       run: |
         ./scripts/deploy.sh
       shell: bash
       env:
         SERVER: "<SERVER-IP>"
         DEPLOY_USER: "github"
     ```

1. Save, commit and push the file to master. This should trigger a deployment. Follow the progress on Github as in previous steps.

1. On your local machine, curl the application and make sure it responds as expected.

# Follow up exercises

If you've finished all the steps above you can pick one of the following extra exercises.

## Set up server maintenance

Set up periodic clean up of the application deployments in `/opt/cygni`. For example

- Every hour, make sure that there are no more than 10 deployments

You can use `crontab` for this.

## Set up multiple environments

For example on push to master, we deploy to a staging environment, but on a tag, we deploy to the production environment.

If you are feeling more ambitious, set up a reverse proxy (haproxy, nginx) in front of the environments.
