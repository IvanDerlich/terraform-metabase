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

# Added jq here for parsing JSON responses easily
sudo apt install ca-certificates curl gnupg jq -y
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

# Run Metabase container
sudo docker run -d -p 3000:3000 --name metabase metabase/metabase:latest 

# -------------------------------------------------------------
# Metabase Headless Admin Setup
# -------------------------------------------------------------
echo "[INFO] Waiting for Metabase container to finish booting..."

# Metabase takes 30-60s on average to complete JVM startup and database migrations
until curl -s http://localhost:3000/api/health | grep -q '"status":"ok"'; do
  echo "Metabase is still starting up... retrying in 5 seconds."
  sleep 5
done

echo "[OK] Metabase is healthy. Extracting setup token..."

# Fetch setup token (only exists before setup is completed)
SETUP_TOKEN=$(curl -s http://localhost:3000/api/session/properties | jq -r '."setup-token"')

SETUP_FIRST_NAME="${setup_first_name}"
SETUP_LAST_NAME="${setup_last_name}"
SETUP_EMAIL="${setup_email}"
SETUP_PASSWORD="${setup_password}"

if [ -n "$SETUP_TOKEN" ] && [ "$SETUP_TOKEN" != "null" ]; then
  echo "[INFO] Submitting setup API request..."

  SETUP_PAYLOAD=$(jq -n \
    --arg token "$SETUP_TOKEN" \
    --arg first_name "$SETUP_FIRST_NAME" \
    --arg last_name "$SETUP_LAST_NAME" \
    --arg email "$SETUP_EMAIL" \
    --arg password "$SETUP_PASSWORD" \
    '{
      token: $token,
      user: {
        first_name: $first_name,
        last_name: $last_name,
        email: $email,
        password: $password
      }
    }')

  curl -X POST http://localhost:3000/api/setup \
    -H "Content-Type: application/json" \
    -d "$SETUP_PAYLOAD"

  echo -e "\n[OK] Metabase user setup complete!"
else
  echo "[WARN] Setup token missing or setup already completed. Skipping creation."
fi

echo "=== Initialization completed: $(date) ==="