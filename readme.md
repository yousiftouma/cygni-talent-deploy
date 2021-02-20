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

## Rationale

Why do we need to know this?

...

## Step 00 - basic deployment

Before involving any CI-server, we will make sure we can automate deployment from our own developer machines. The goal is to be able to deploy our application on a fresh VPS without manual intervention.

### Host machine

Before setting up deployments, the server needs to be created and set up.

1. Create VPS with ubuntu and root ssh login access. (TODO: how do we set this up for everyone?)
1. Install dependencies on server (node, ufw)
1. Set up firewall rules (allow http and ssh)

### Deployment

1. Make sure application is ready for production (test etc...)
1. Copy application to server
1. Create systemd service
1. Start or reload service

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

- Step XX - non-root - create non-root user that runs application
- Step XX - dockerize - dockerize the application to make it more portable (needs a purpose? maybe db?)
- Step XX - reverse-proxy - setup reverse proxy HAProxy/Nginx/Traefik
- Step XX - certificate - letsencrypt
