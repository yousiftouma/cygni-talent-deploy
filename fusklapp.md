# Step 01 - Log in to server

```ssh-config
// ~/.ssh/config
Host cygni-deploy
    HostName <SERVER-IP>
```

```
ssh root@cygni-deploy
```

# Step 02 - Create admin user

```bash
# Add user
adduser <USERNAME>

# Add to group sudo
adduser <USERNAME> sudo

# Check groups
groups <USERNAME>

# Check home directory
ls -la /home
```

# Step 03 - Set up public key authentication

```bash
# Create key
ssh-keygen

# Copy key
ssh-copy-id <USERNAME>@cygni-deploy

# Log in
ssh <USERNAME>@cygni-deploy

# Check key file
# From server
cat ~/.ssh/authorized_keys

# From local
cat ~/.ssh/id_rsa.pub
```

# Step 04 - Secure SSH

OBS `sshd_config.d` INTE `ssh_config.d`

```bash
# Open file
sudo vi /etc/ssh/sshd_config.d/00-setup.conf

# Add and save
PermitRootLogin no
PasswordAuthentication no

# Restart SSHD
sudo systemctl restart sshd

# From local machine, verify denied
ssh root@cygni-deploy
```

# Step 05 - firewall

```bash
# Install/update
sudo apt update
sudo apt install ufw

# Setup up default rules
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Specific rules
sudo ufw allow ssh
sudo ufw allow in 8080/tcp

# Show rules
sudo ufw show added

# Enable
sudo ufw enable

# Show status
sudo ufw status

# From local machine
telnet $SERVER 80 # time out
telnet $SERVER 8080 # established

# From server
sudo ufw reject 80

# From local machine
telnet $SERVER 80

# From server
sudo ufw status numbered
sudo ufw delete NUM
```

# Step 06 - Dependencies

```bash
# Goto https://nodejs.org/en/download/package-manager/

curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install nodejs

# Check version
node -v
npm -v
```

# Step 07 - Service

```bash
# Create tarball with source code
tar -czf tmp_cygni-service.tar.gz src/ package.json package-lock.json

# Copy to server
scp tmp_cygni-service.tar.gz <USERNAME>@cygni-deploy:/tmp/cygni-service.tar.gz

# From server, create directory
sudo mkdir -p /opt/cygni/app
cd /opt/cygni/app

# Unpack tarball
sudo tar -xzf ~/cygni-service.tar.gz

# Install dependencies
npm ci --production

# Run
npm start

# From local machine
curl $SERVER:8080
```

# Step 08 - Deployment

```bash
# Create system user
adduser --system cygni

# Create unit file
sudo vi /etc/systemd/cygni.service

"
[Unit]
Description=Cygni Competence Deploy

[Service]
User=cygni
ExecStart=/usr/bin/env npm start
Environment=NODE_ENV=production
Environment=PORT=8080
WorkingDirectory=/opt/cygni/app

[Install]
WantedBy=multi-user.target
"

# Start service
sudo systemctl start cygni

# From local machine
curl $SERVER:8080

# Show logs on server
journalctl -f --unit cygni
```

# Step 09 - Scripted deployment

```bash
# run script
./scripts/deploy.sh # -> permission denied

# create user
sudo addgroup deployers
sudo adduser <USERNAME> deployers

sudo chown -R :deployers /opt/cygni
sudo chmod 775 /opt/cygni

sudo chown :deployers /etc/systemd/system/cygni.service
sudo chmod 664 /etc/systemd/system/cygni.service

# add sudoers
sudo visudo -f /etc/sudoers.d/00-deployers
%deployers ALL=NOPASSWD:/bin/systemctl daemon-reload, /bin/systemctl restart cygni

# from local machine run script again
export DEPLOY_USER=<USERNAME>
./scripts/deploy.sh

# change something in response and deploy again
```

# Step 10 - Set up CI

```
# Do github action, add steps
   - name: Set up node
     uses: actions/setup-node@v2
     with:
        node-version: "14"

   - name: Test
     run: npm test

# Save and commit. Trigger action
```

# Step 11 - Set up static code analysis

```bash
# Install eslint
npm i --save-dev eslint
npx eslint --init
npx eslint src

# Add step

- name: Lint
  run: npm run lint

# Install prettier
npm i --save-dev prettier
echo '{}' > .prettierrc.json
touch .prettierignore
npx prettier --check src

# Add step
- name: Format check
  run: npm run format

# Push and watch action
```

# Step 12 - Github Actions deployment

```bash
# Create user
sudo adduser github --disabled-password
sudo adduser github deployers

# From local machine
ssh-keygen -f id_github
ssh-keyscan $SERVER > known_hosts

# From local machine
scp id_github.pub <USERNAME>@cygni-deploy:/tmp/id_github.pub

# From server
sudo mkdir -p /home/github/.ssh
sudo chown github:github /home/github/.ssh
sudo chmod 700 /home/github/.ssh
sudo mv /tmp/id_github.pub /home/github/.ssh/authorized_keys
sudo chown github:github /home/github/.ssh/authorized_keys
sudo chmod 600 /home/github/.ssh/authorized_keys

# Test the ssh connection
ssh -i id_github github@cygni-deploy

# Upload secrets, add steps
- name: Set up ssh
  run: |
    mkdir -p ~/.ssh
    echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
    chmod 600 ~/.ssh/id_rsa
  env:
    SSH_PRIVATE_KEY: ${{secrets.SSH_PRIVATE_KEY}}
    SSH_KNOWN_HOSTS: ${{secrets.SSH_KNOWN_HOSTS}}

- name: Deploy
  run: |
    ./scripts/deploy.sh
  shell: bash
  env:
    SERVER: "<SERVER-IP>"
    DEPLOY_USER: "github"

# Try it out
```
