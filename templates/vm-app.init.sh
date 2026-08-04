#!/usr/bin/env bash

# Stop on error (-e), treat unset variables as error (-u), print commands (-x)
set -euxo pipefail

LOG_DIR="/var/log/tf-init"
LOG_FILE="$LOG_DIR/init_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

exec > >(tee -i -a "$LOG_FILE") 2>&1

echo "=== Initialization started: $(date) ==="

sudo apt update 
# sudo apt upgrade -y

sudo apt install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update


sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y



sudo systemctl start docker 
sudo systemctl enable docker
sudo docker run -d -p 3000:3000 --name metabase metabase/metabase:latest 

echo "=== Initialization completed: $(date) ==="
