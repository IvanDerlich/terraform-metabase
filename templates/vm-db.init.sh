#!/usr/bin/env bash
${common_header}

echo "=== DB Initialization started: $(date) ==="

# --- INSTALLATION ---
sudo apt update
# sudo apt upgrade -y
sudo apt install mysql-server -y

# Update mysqlx-bind-address to 0.0.0.0
sudo sed -i 's/^\s*#\?\s*bind-address\s*=.*/bind-address = 0.0.0.0/' $(grep -rl "bind-address" /etc/mysql/)
sudo sed -i 's/^\s*#\?\s*mysqlx-bind-address\s*=.*/mysqlx-bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL to apply changes
sudo systemctl restart mysql

# --- DATABASE AND USERS ---
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS metabase;
CREATE USER IF NOT EXISTS 'metabase_admin'@'%' IDENTIFIED BY '${db_password}';
ALTER USER 'metabase_admin'@'%' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON metabase.* TO 'metabase_admin'@'%';
FLUSH PRIVILEGES;
EOF

# --- USER AND PERMISSIONS VERIFICATION ---
echo "Verifying user creation and permissions..."

# 1. Check whether the user exists
USER_EXISTS=$(sudo mysql -sse "SELECT COUNT(*) FROM mysql.user WHERE user='metabase_admin' AND host='%';")

if [ "$USER_EXISTS" -eq 1 ]; then
    echo "[OK] User 'metabase_admin' exists."
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
if mysql --protocol=TCP --host=127.0.0.1 --user=metabase_admin --password="${db_password}" -e "USE metabase; SELECT 1;" >/dev/null 2>&1; then
    set -x
    echo "[OK] Login with metabase_admin and db_password verified."
else
    set -x
    echo "[ERROR] Authentication failed for metabase_admin using db_password." >&2
    exit 1
fi

# 4. Load mobility dataset dump
dump_deadline=$((SECONDS + 600))
until [ -f /home/ubuntu/google-mobility.sql.gz ]; do
  [ $SECONDS -ge $dump_deadline ] && { echo "[ERROR] google-mobility.sql.gz not uploaded after 10 min" >&2; exit 1; }
  echo "[WAIT] Waiting for google-mobility.sql.gz upload... ($SECONDS s elapsed)"
  sleep "$POLL_INTERVAL"
done

gunzip -f /home/ubuntu/google-mobility.sql.gz

if [ ! -f /home/ubuntu/google-mobility.sql ]; then
    echo "[ERROR] File /home/ubuntu/google-mobility.sql was not created after unzip." >&2
    exit 1
fi

sudo mysql metabase < /home/ubuntu/google-mobility.sql
rm -f /home/ubuntu/google-mobility.sql
echo "[OK] Mobility dataset imported and temporary SQL file removed."

echo "=== DB Initialization completed: $(date) ==="