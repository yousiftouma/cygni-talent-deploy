# CI/CD from scratch

This is a course in Continuous Integration and Continuous Deployment from scratch. That means we are not going to use any off-the-shelf products such as heroku to achieve this. We are going to use a Linux server that we access through ssh.

## Goals

The goal of this course is to be able to set up simple automated deployments from scratch.

- Managing linux servers through SSH
- Managing linux services using systemd
- Managing application secrets and tokens
- Securing linux servers
- Automating repetitive tasks

## Purpose

The purpose is to gain practical knowledge of how to set up services on linux servers from scratch.

## Agenda

- Presentation CI/CD
- Walk through step 00 - 04
- Do step 04 - 12

- TODO(emil): Script för att rätta allas servrar
  - Rätt portar öppna
  - Inte ssh:a in som root

## Pre requisites

- Fork this repository to your own GitHub account
- Terminal installed
  - Windows WSL
- node v14+ with npm

TODO(emil): Add list and links

### Required tools

These tools needs to be available on your local machine

- `git`
- `ssh`
- `ssh-copy-id`
- `ssh-keygen`
- `ssh-keyscan`
- `scp`
- `tar`
- `echo`
- `node` v14+
- `npm` v6+
- `curl`
- `telnet`
- `nmap`

### Other tools

The following is a list of programs you need to know how to run on the server. Check their manuals

- `tee`
- `systemctl`
- `sudo`
- `mkdir`
- `chown`
- `chmod`
- `adduser`
- `groups`
- `visudo`

### Other

- systemd https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files

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

### Changing ownership and permissions

Arch wiki has good articla about file permissions and attributes [here](https://wiki.archlinux.org/index.php/File_permissions_and_attributes).

[Here](https://chmod-calculator.com/) is a handy tool to visualize the different representations of file permissions.

Here are some example usages of `chmod`, `chgrp` and `chmod`

- Make `/path/to/file` read and writable for owner, but no one else

  ```
  chmod 600 /path/to/file
  ```

- Change owner of `/path/to/file` to `user`

  ```
  chown user /path/to/file
  ```

- Change group of `/path/to/file` to `group`

  ```
  chgrp group /path/to/file
  ```

  or

  ```
  chown :group /path/to/file
  ```

## Step 00 - Fork this repo

Make a fork of this repo to your own account on GitHub. This is so that you can checkin stuff and activate GitHub actions.

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

1. Test the firewall using `telnet` on your local machine and `nc` on the server.

   Use `nc -l 8080` to listen for incoming connections on the server.

   Use `telnet <SERVER-IP> 8080` to initiate a connection on the server.

   Try this on both opened and denied ports.

   - For _denied_ ports, the connection will timeout.
   - For _allowed_ ports, a connection should be opened.
   - If you chose _reject_ instead if _deny_, you will get a "Connection refused" error.

1. You can also try the cli portscanner `nmap` used in [Matrix](https://www.youtube.com/watch?v=0PxTAn4g20U) to see which ports are open.

   Use `nmap -Pn <SERVER-IP>` to list open ports on your server.

## Step 06 - Dependencies

Our application needs node.js installed to run. Install the latest LTS version (14.x). See https://nodejs.org/en/download/package-manager/

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
   curl <SERVER-IP>:8080
   ```

   You should receive a "Hello World!" reply. If not, use error messages to trace back where something could have gone wrong. Ask for help if needed.

1. On the server, stop the application.

## Step 08 - Deployment

In the previous step, we ran the application in the foreground. The application should run in the background so that it can continue to run even after we log out from the server. We can achieve this by running it using `systemd`. `systemd` is a system and service manager for linux. It is configured by adding unit files in the `/etc/systemd` directory. The tool `systemctl` is used to control `systemd`. See `man systemd` for more information.

1. On the server, create a new system user using `adduser --system cygni`. This will create an unprivileged, passwordless and groupless user that we will use to run our application on the server.

1. On the server, create a new systemd service by creating a file `/etc/systemd/system/cygni.service`.

   ```
   [Unit]
   Description=Cygni Talent Deploy

   [Service]
   User=cygni
   ExecStart=/usr/bin/env npm start
   Environment=NODE_ENV=production
   Environment=PORT=8080
   WorkingDirectory=/opt/cygni/app
   ```

1. On the server, start the service using `systemctl`. See `man systemctl` for instructions.

1. On your local machine, test the service using curl.

   ```
   curl <SERVER-IP>:8080
   ```

1. On the server, you can follow the logs using `sudo journalctl --follow --unit cygni`

## Step 09 - Scripted deployment

Next step is to automate the tasks in the previous step. The script [`./scripts/deploy.sh`](./scripts/deploy.sh) is performing the same tasks. However, if you try to run it now, you will get some permissions errors. We will solve this by adding a new group called `deployers` for more granular permission control. Users in this group should have sufficient permissions for deploying our application, but not more!

The `deployers` group will have group ownership and write permissions to the `/opt/cygni` directory and the `/etc/systemd/system/cygni.service`. In addition, they will have passwordless access to the commands to restart the `cygni` service.

1. On the server, add a new group called `deployers`. See `man addgroup`.

1. On the server, add your admin account to the `deployers` group.

   Verify using `groups` command

   ```
   groups <USERNAME>
   <USERNAME>: <USERGROUP> sudo deployers
   ```

1. On the server, change the group ownership of `/opt/cygni` to `deployers`. See `man chgrp`.

1. On the server, change the permissions to allow the deployers group to read, write and traverse the `/opt/cygni` directory. See `man chmod`.

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

   Set the environment variable `DEPLOY_USER` to specify the username of your admin user on the server. Also set the SERVER variable to point to your server's IP in the same manner. Make sure that no interactive password prompts appear.

   ```
   export DEPLOY_USER=<USERNAME>
   export SERVER=<SERVER-IP>
   ./scripts/deploy.sh
   ```

1. On the server, check the logs in `journalctl`, you should be able to see that the server was restarted.

1. On your local machine, make some edits to the Hello World reply in `src/server.js`, then rerun the deploy script.

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

1. Add a step for installing dependencies using the command `npm ci`

1. Add a step for running the unit tests using the command `npm test`

1. Save and commit the file to master. Now you should be able to see the workflow under the "Actions" tab. If you kept the "workflow_dispatch:" property from the skeleton, you can manually trigger the workflow from the github GUI as well. Move on once you have made sure that the workflow works as expected.

## Step 11 - Set up static code analysis

In this step, we are going to add some tools that runs static code analysis on the code base. These tools should be added as part of the Github Actions workflow defined in the previous step. In effect, we will get broken builds whenever the master branch contains bad code.

1. Install eslint - follow instructions on https://eslint.org/docs/user-guide/getting-started

   When asked "How would you like to use ESLint?". Choose either "To check syntax only" or "To check syntax and find problems". The last option to "enforce code style" is more commonly the responsibility of a code formatter.

1. Run eslint as part of the Github Actions workflow.

   It is common to add an npm script for linting similar to the `test` script that is already added in `package.json`. For example

   ```
   "lint": "eslint src/"
   ```

   ESLint can then be invoked by running `npm run lint` in the repository root.

1. Install prettier - follow instructions on https://prettier.io/docs/en/install.html

1. Run prettier as part of the Github Actions workflow.

   As hinted in the documentation, it is common to run `prettier --check` as part of the CI setup. This can be added as an additional npm script, or as part of the lint step.

1. Push some intentially bad code to the master branch, follow the build and observe the failed build.

## Step 12 - Github Actions deployment

Time to enable github to deploy our application. We need to create a new user on the server called `github` which our github action will use when logging in to the server. This user will be in group `deployers`, which we've already made sure has sufficient permissions to deploy the application.

TODO: Explain that we need to set up a new SSH key for this user

1. On the server, add a new user called `github` make sure to use `--disabled-password` flag to skip password set up for this user.

1. On the server, add the `github` user to the group `deployers`.

1. On your local machine, create a new SSH-key, name it to something appropriate, like `cygni_id_github` and store it somewhere temporarily. You should delete it from your machine as soon as you have uploaded it to github.

   ```
   ssh-keygen -f cygni_id_github
   ```

1. On your local machine, scan the server for its public keys and save it to a known_hosts file next to the keys generated in the previous step. We will upload this to github as well to verify that the servers host keys are not changed.

   ```
   ssh-keyscan <SERVER-IP> > cygni_known_hosts
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

## Clean up old deployments

The current script creates a new directory for each deployment. Make sure that only the 5 latest deployments are kept on disk.

**hint** look at commands `ls`, `sort`, `find`, `wc` and `rm`

## Set up multiple environments

We can host multiple versions of the application on the same server as long as they are listening on different ports. Create and/or modify github actions that deploys staging and production versions of your application.

You can set this up in many different ways, for example:

- On push to master, deploy staging environment.
- On tag creation, deploy production environment.

If you are feeling more ambitious, set up a reverse proxy (haproxy, nginx) in front of the environments.
