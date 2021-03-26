# Steg 1 - Sätt upp SSH-access för root

Om ni inte redan har en, skapa en SSH-nyckel.

```bash
ssh-keygen
```

Lägg till servern i ~/.ssh/config (vill man använda en annan fil och vet hur man gör så funkar det lika bra).

```ssh-config
Host cygni-deploy
    HostName 192.46.239.99
```

Kopiera över eran publika ssh-nyckel.

```bash
ssh-copy-id root@cygni-deploy
```

SSH-a in på servern

```bash
ssh root@cygni-deploy
```

# Steg 2 - Skapa användare

Inne på servern, skapa admin användare tillhörande sudo.

```bash
adduser <USERNAME>
```

Lägg till användaren i gruppen sudo

```
adduser <USERNAME> sudo
```

Visa vilka grupper användaren tillhör (adduser skapar grupp med namn <USERNAME>)

```
groups <USERNAME>
```

Autorisera dig själv att logga in som nya användaren, enklast är att kopiera `authorized_keys` från root-användaren.

```bash
mkdir -p /home/<USERNAME>/.ssh
cp /root/.ssh/authorized_keys /home/<USERNAME>/.ssh/
```

Sätt rätt ägarskap och rättigheter

```bash
chown -R <USERNAME>:<USERNAME> /home/<USERNAME>/.ssh
chmod 644 /home/<USERNAME>/.ssh/authorized_keys
```

Logga ut som root och lägg testa logga in som den nya användaren.

```
ssh <USERNAME>@cygni-deploy
```

# Steg 3 - Spärra root

OBS `sshd_config.d` INTE `ssh_config.d`

```bash
sudo vi /etc/ssh/sshd_config.d/00-setup.conf
```

Lägg till

```bash
PermitRootLogin no
PasswordAuthentication no
```

Starta om sshd

```bash
sudo systemctl restart sshd
```

Logga ut eller byt terminal se till att du får permission denied

```
ssh root@cygni-deploy
```

# Steg 4 - Brandvägg

Inne på servern

```
sudo apt update
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow in 8080/tcp

sudo ufw enable
```

# Steg 4 - Node.js

Börja med att kopiera över appen från _lokal_ maskin

```bash
tar -czf tmp_cygni-service.tar.gz src/ package.json package-lock.json
scp tmp_cygni-service.tar.gz <USERNAME>@cygni-deploy:~/cygni-service.tar.gz
```

In på servern igen, install nodejs

```
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install nodejs
```

Packa upp appen på ett väl valt ställe

```bash
sudo mkdir -p /opt/cygni/app
cd /opt/cygni/app
sudo tar -xzf ~/cygni-service.tar.gz
npm ci --production
```

Nu kan vi köra tjänsten

```
npm start
```

Curla från lokal maskin

```
curl $SERVER:8080
```

# Steg 5 - Service

Vi ska givetvis köra appen i bakgrunden som en tjänst.

Skapa en systemanvändare

```
adduser --system cygni
```

Skapa en systemd unit `/etc/systemd/cygni.service`

```
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
```

Starta

```
sudo systemctl start cygni
```

Visa att den kör

```
curl $SERVER:8080
```

Illustrera en deploy genom att ändra i index-filen. Lägg till ett log-statement.

Repetera sedan tar, scp, untar och avsluta med `systemctl restart cygni` så borde man se att det lirar.

Visa `sudo journalctl -f --unit cygni`

# Steg 6 - Scriptad deploy

Skapa en grupp som har tillräckligt med permissions för att deploya. Lägg till admin i den gruppen.

```
sudo addgroup deployers
sudo adduser <USERNAME> deployers

sudo chown -R :deployers /opt/cygni
sudo chmod 775 /opt/cygni

sudo chown :deployers /etc/systemd/system/cygni.service
sudo chmod 664 /etc/systemd/system/cygni.service
```

Lägg till kommandon i en sudoers fil /etc/sudoers.d/00-deployers

```
%deployers ALL=NOPASSWD:/bin/systemctl daemon-reload, /bin/systemctl restart cygni
```

Kör deploy-scriptet

```
export DEPLOY_USER=<USERNAME>

./scripts/deploy.sh
```

# Steg 7 - Deploya från github

```
SERVER> sudo adduser github --disabled-password
SERVER> sudo adduser github deployers
```

Ingen passphrase

```sh
LOCAL> ssh-keygen -f id_github
LOCAL> ssh-keyscan $SERVER > known_hosts
```

Kopiera _publika_ nykeln till servern

```sh
LOCAL> scp id_github.pub <USERNAME>@cygni-deploy:~
```

Navigera till hemkatalogen och flytta filen till /home/github

```sh
SERVER> sudo mkdir -p /home/github/.ssh
SERVER> sudo chown github:github /home/github/.ssh
SERVER> sudo mv ~/id_github.pub /home/github/.ssh/authorized_keys
SERVER> sudo chown github:github /home/github/.ssh/authorized_keys
SERVER> sudo chmod 644 /home/github/.ssh/authorized_keys
```
