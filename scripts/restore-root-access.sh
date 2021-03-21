#!/bin/bash
# This script can be used to restore root access to the server if you need to change
# rerun the setup-admin for some reason
set -e

echo "
PermitRootLogin yes
PasswordAuthentication yes
" | ssh -F .ssh/config admin@cygni "cat - > /tmp/sshd_config"
ssh -t -F .ssh/config admin@cygni "sudo mv /tmp/sshd_config /etc/ssh/sshd_config.d/setup.conf && sudo systemctl restart sshd"
