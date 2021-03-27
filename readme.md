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

<!-- - **server** - the host server
- ** -->

## Step 01 - Set up SSH-access for root user

Initially, you will only be able to log in to the server using the root user with the provided password. The first thing we want to do is to enable login using an SSH key. It is easier and more secure.

1. Create a new ssh key using the tool `ssh-keygen`. You can use the default options when prompted. If you already have an SSH-key on your machine, you can skip this step and just use that key. You will be prompted if you want to overwrite your previous key it **DON'T overwrite it if you already use it for other things**.

1. Add an entry for your server in your ~/.ssh/config file. This enables us to set up a friendly name and some convenient config for our server. Check `man ssh_config` for more information.

   ```
   Host cygni-deploy
      HostName <SERVER>
   ```

   Note, if you know how to, you can skip this step or use another file for this config.

1. Copy your public SSH-key to the server to allow root login using SSH. The simplest way is to use the utility `ssh-copy-id`. The following command will copy your public keys from `~/.ssh/` into `/root/.ssh/authorized_keys` on the server. Check `man ssh-copy-id` for more information. You will be prompted for the root password.

   ```
   ssh-copy-id root@cygni-deploy
   ```

1. Now, you should be able to log in to the server using your SSH key instead of password. The command for logging in is simply `ssh <USER>@<SERVER>`. As there are no other users at the moment, you have to log in as the `root` user.

   ```
   ssh root@cygni-deploy
   ```

## Step 02 - Create admin user

It is widely considered bad practise to use directly use root for administrative tasks on linux servers. The root user has permissions to do anything without restrictions. The recommended approach is to create an admin user that has priviliges to run commands _as_ root using `sudo`. See `man sudo` for more information.

Usually, admin accounts should be personal. They are then given administrative powers by belonging to a certain group. In this case, the group will be `sudo`. The `sudo` group by default has permissions to run any command as any user, as long as the user provides their password.

1. Create a new user with default settings. The simplest way is to use the `adduser`. See `man adduser`. Make sure you remember the password provided.

1. Add the user to the group `sudo`.

1. You can check which groups a user belongs to using the command.

   ```
   groups <USERNAME>
   ```

   The expected output is `<USERNAME>: <USERNAME> sudo`. As explained in the documentation `adduser` will create a group with the same name as the created user by default.

1. Make sure that the new /home directory have been created correctly.

   ```
   ls -la /home
   drwxr-xr-x  5 root        root         4096 Mar 26 12:00 .
   drwxr-xr-x 20 root        root         4096 Mar 26 12:00 ..
   drwxr-xr-x  7 <USERNAME>  <USERGROUP>  4096 Mar 26 12:00 <USERNAME>
   ```

   <USERNAME> and <USERGROUP> should be the owners of the /home/<USERNAME> directory. If not, something might have gone a little wrong.

## Step 03 - Set up SSH access for admin user

There is a new admin user, but we can still only access the server by logging in as root through SSH. To give yourself access to login as the admin user, we need to add your public key to that users own `authorized_keys` file. Because we already added our public key to the root users authorized keys, the simplest way is to copy the `/root/.ssh/authorized_keys` to `/home/<USERNAME>/.ssh`.

It is also important that the correct permissions are set on the `authorized_keys` file. It should be _owned_ by the applicable user.

1. Copy `/root/.ssh/authorized_keys` to `/home/<USERNAME>/.ssh/authorized_keys` on the server.

1. Make sure the correct permissions are set on the `authorized_keys` file. It The ssh is particular about
