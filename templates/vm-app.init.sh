#!/usr/bin/env bash
${common_header}

echo "=== App Initialization started: $(date) ==="

sudo apt update 
# sudo apt upgrade -y

# Added jq here for parsing JSON responses easily
sudo apt install ca-certificates curl gnupg jq netcat-openbsd default-mysql-client -y
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

# --- DB READINESS POLLS ---
port_deadline=$((SECONDS + 300))
until nc -z "${db_ip}" 3306 2>/dev/null; do
  [ $SECONDS -ge $port_deadline ] && { echo "[ERROR] DB port 3306 unreachable after 5 min" >&2; exit 1; }
  echo "[WAIT] DB port not yet reachable... ($SECONDS s elapsed)"
  sleep "$POLL_INTERVAL"
done
echo "[OK] DB port 3306 reachable"

set +x  # avoid logging DB password in polls 2 and 3
auth_deadline=$((SECONDS + 300))
until mysql -h "${db_ip}" -u metabase_admin -p"${db_password}" -e "SELECT 1;" metabase >/dev/null 2>&1; do
  [ $SECONDS -ge $auth_deadline ] && { echo "[ERROR] Cannot authenticate to DB after 5 min" >&2; exit 1; }
  echo "[WAIT] Waiting for DB auth... ($SECONDS s elapsed)"
  sleep "$POLL_INTERVAL"
done
echo "[OK] DB auth verified"

data_deadline=$((SECONDS + 600))
until [ "$(mysql -h "${db_ip}" -u metabase_admin -p"${db_password}" -sse 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema="metabase";' 2>/dev/null)" -gt 0 ] 2>/dev/null; do
  [ $SECONDS -ge $data_deadline ] && { echo "[ERROR] Mobility data not loaded in DB after 10 min" >&2; exit 1; }
  echo "[WAIT] Waiting for mobility data in DB... ($SECONDS s elapsed)"
  sleep "$POLL_INTERVAL"
done
set -x
echo "[OK] Mobility data loaded in DB"

# -------------------------------------------------------------
# Metabase Headless Admin Setup
# -------------------------------------------------------------
echo "[INFO] Waiting for Metabase container to finish booting..."

# Metabase takes 30-60s on average to complete JVM startup and database migrations
until curl -s http://localhost:3000/api/health | grep -q '"status":"ok"'; do
  echo "[WAIT] Metabase still starting up... ($SECONDS s elapsed)"
  sleep "$POLL_INTERVAL"
done

echo "[OK] Metabase is healthy. Extracting setup token..."

# Fetch setup token (only exists before setup is completed)
SETUP_TOKEN=$(curl -s http://localhost:3000/api/session/properties | jq -r '."setup-token"')

if [ -n "$SETUP_TOKEN" ] && [ "$SETUP_TOKEN" != "null" ]; then
  echo "[INFO] Submitting setup API request with DB connection..."

  SETUP_PAYLOAD=$(jq -n \
    --arg token "$SETUP_TOKEN" \
    --arg first_name "${setup_first_name}" \
    --arg last_name "${setup_last_name}" \
    --arg email "${setup_email}" \
    --arg password "${setup_password}" \
    --arg db_host "${db_ip}" \
    --arg db_name "metabase" \
    --arg db_user "metabase_admin" \
    --arg db_password "${db_password}" \
    '{
      token: $token,
      user: {
        first_name: $first_name,
        last_name: $last_name,
        email: $email,
        password: $password
      },
      database: {
        name: "Primary MySQL",
        engine: "mysql",
        details: {
          host: $db_host,
          port: 3306,
          dbname: $db_name,
          user: $db_user,
          password: $db_password,
          ssl: false
        },
        auto_run_queries: true,
        is_full_sync: true,
        is_on_demand: false
      }
    }')

  HTTP_CODE=$(curl -sS -o /tmp/metabase-setup-response.json -w "%%{http_code}" -X POST http://localhost:3000/api/setup \
    -H "Content-Type: application/json" \
    -d "$SETUP_PAYLOAD")

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo -e "\n[OK] Metabase user setup complete with DB connection to ${db_ip}:3306."
  else
    echo "[WARN] Setup with DB connection failed (HTTP $HTTP_CODE). Trying user-only setup."
    cat /tmp/metabase-setup-response.json || true

    SETUP_PAYLOAD_NO_DB=$(jq -n \
      --arg token "$SETUP_TOKEN" \
      --arg first_name "${setup_first_name}" \
      --arg last_name "${setup_last_name}" \
      --arg email "${setup_email}" \
      --arg password "${setup_password}" \
      '{
        token: $token,
        user: {
          first_name: $first_name,
          last_name: $last_name,
          email: $email,
          password: $password
        }
      }')

    HTTP_CODE_FALLBACK=$(curl -sS -o /tmp/metabase-setup-fallback-response.json -w "%%{http_code}" -X POST http://localhost:3000/api/setup \
      -H "Content-Type: application/json" \
      -d "$SETUP_PAYLOAD_NO_DB")

    if [ "$HTTP_CODE_FALLBACK" -ge 200 ] && [ "$HTTP_CODE_FALLBACK" -lt 300 ]; then
      echo "[WARN] Metabase setup completed without DB connection. Configure DB in Metabase settings/API later."
    else
      echo "[ERROR] User-only fallback setup failed (HTTP $HTTP_CODE_FALLBACK)." >&2
      cat /tmp/metabase-setup-fallback-response.json || true
      exit 1
    fi
  fi
else
  echo "[WARN] Setup token missing or setup already completed. Skipping creation."
fi

echo "=== App Initialization completed: $(date) ==="