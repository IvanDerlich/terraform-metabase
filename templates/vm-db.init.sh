#!/usr/bin/env bash

# Stop on error (-e), treat unset variables as error (-u), print commands (-x)
set -euxo pipefail

LOG_DIR="/var/log/tf-init"
LOG_FILE="$LOG_DIR/init_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "$LOG_DIR"

exec > >(tee -i -a "$LOG_FILE") 2>&1

echo "=== Initialization started: $(date) ==="

# --- INSTALLATION ---
sudo apt update
# sudo apt upgrade -y
sudo apt install mysql-server vim -y

# --- NETWORK CONFIGURATION (OVERRIDE) ---
sudo bash -c 'cat << EOF > /etc/mysql/mysql.conf.d/99-custom.cnf
[mysqld]
bind-address        = 0.0.0.0
mysqlx-bind-address = 0.0.0.0
EOF'

sudo chmod 644 /etc/mysql/mysql.conf.d/99-custom.cnf
sudo systemctl restart mysql

# --- DATABASE AND USERS ---
DB_PASS="${db_password}"
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS metabase;
CREATE USER IF NOT EXISTS 'metabase_admin'@'%' IDENTIFIED BY '$${DB_PASS}';
ALTER USER 'metabase_admin'@'%' IDENTIFIED BY '$${DB_PASS}';
GRANT ALL PRIVILEGES ON metabase.* TO 'metabase_admin'@'%';
FLUSH PRIVILEGES;
EOF

# --- USER AND PERMISSIONS VERIFICATION ---
echo "Verifying user creation and permissions..."

# 1. Check whether the user exists
USER_EXISTS=$(sudo mysql -sse "SELECT COUNT(*) FROM mysql.user WHERE user='metabase_admin' AND host='%';")

if [ "$USER_EXISTS" -eq 1 ]; then
    echo "[OK] User 'metabase_admin'@'%' exists."
else
    echo "[ERROR] User 'metabase_admin'@'%' was not created." >&2
    exit 1
fi

# 2. Check whether the database exists
DB_EXISTS=$(sudo mysql -sse "SHOW DATABASES LIKE 'metabase';")

if [ "$DB_EXISTS" == "metabase" ]; then
    echo "[OK] Database 'metabase' exists."
else
    echo "[ERROR] Database 'metabase' was not created." >&2
    exit 1
fi

# 3. Verify real authentication using configured password
set +x
if mysql --protocol=TCP -h 127.0.0.1 -u metabase_admin -p"$DB_PASS" -e "USE metabase; SELECT 1;" >/dev/null 2>&1; then
    set -x
    echo "[OK] Login with metabase_admin and DB_PASS verified."
else
    set -x
    echo "[ERROR] Authentication failed for metabase_admin using DB_PASS." >&2
    exit 1
fi

echo "=== Initialization completed: $(date) ==="