#!/bin/bash
set -e

source .env

mkdir -p .ssh
ssh-keyscan $SERVER > ./.ssh/known_hosts

function create_ssh_key {
    if test -f $1; then
        echo "$1 already exists"
    else
        echo "create ssh key $1"
        ssh-keygen -f $1 -t rsa -b 4096
    fi
}

create_ssh_key ./.ssh/admin
create_ssh_key ./.ssh/deploy

echo "
Host cygni
    HostName $SERVER
    UserKnownHostsFile $(realpath ./.ssh/known_hosts)

Match user root
    IdentityFile ~/.ssh/id_rsa
    # PasswordAuthentication yes

Match user admin
    IdentityFile $(realpath ./.ssh/admin)

Match user deploy
    IdentityFile $(realpath ./.ssh/deploy)
" > ./.ssh/config
