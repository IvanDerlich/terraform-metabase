#!/usr/bin/env bash
${common_header}

echo "=== Front End Initialization started: $(date) ==="

sudo apt update
# sudo apt upgrade -y

sudo apt install nginx curl -y

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

echo "[INFO] Nginx is ready — visit: ${fe_url} (Metabase not ready yet)"

metabase_deadline=$((SECONDS + 600))
until curl -s "http://${app_ip}:3000/api/health" | grep -q '"status":"ok"'; do
  [ $SECONDS -ge $metabase_deadline ] && { echo "[ERROR] Metabase did not become ready after 10 min" >&2; exit 1; }
  echo "[WAIT] Metabase not ready yet... ($SECONDS s elapsed)"
  sleep "$POLL_INTERVAL"
done
echo "[OK] Metabase is ready — visit: ${fe_url}"

echo "=== Front End Initialization completed: $(date) ==="
