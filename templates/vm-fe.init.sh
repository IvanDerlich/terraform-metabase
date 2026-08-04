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

sudo apt install nginx vim curl -y

sudo rm -f /etc/nginx/sites-enabled/default
sudo mkdir -p /etc/nginx/conf.d

sudo tee /etc/nginx/conf.d/lb.conf << EOF
server {
  listen 80;

  location = /healthz {
    access_log off;
    default_type text/plain;
    return 200 'ok';
  }

  location / {
    proxy_pass http://${app_ip}:3000;
    proxy_http_version 1.1;
    proxy_set_header Connection 'Upgrade';
    proxy_set_header Upgrade \$http_upgrade;
  }
}
EOF

if [ -f /etc/nginx/conf.d/lb.conf ]; then
  echo "[OK] Nginx config file /etc/nginx/conf.d/lb.conf exists"
else
  echo "[ERROR] Nginx config file /etc/nginx/conf.d/lb.conf was not created" >&2
  exit 1
fi

sudo nginx -t
echo "[OK] Nginx configuration syntax is valid"

sudo systemctl restart nginx
sudo systemctl is-active --quiet nginx
echo "[OK] Nginx service is active"

if sudo ss -ltn | grep -q ":80"; then
  echo "[OK] Nginx is listening on port 80"
else
  echo "[ERROR] Nginx is not listening on port 80" >&2
  exit 1
fi

if curl --silent --show-error --fail --max-time 10 "http://127.0.0.1/healthz" >/dev/null; then
  echo "[OK] Nginx local health check succeeded"
else
  echo "[ERROR] Nginx local health check failed" >&2
  exit 1
fi

echo "=== Initialization completed: $(date) ==="
