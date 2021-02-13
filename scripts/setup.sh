# setup service user
USERNAME=cygni
useradd -m $USERNAME || true
mkdir /home/$USERNAME/.ssh -p
cp .ssh/authorized_keys /home/$USERNAME/.ssh/authorized_keys

chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
chmod 0700 /home/$USERNAME/.ssh
chmod 0600 /home/$USERNAME/.ssh/authorized_keys

# setup dependencies
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
apt update
apt install -y ufw nodejs git

# setup firewall
ufw allow ssh
ufw allow http
ufw --force enable
