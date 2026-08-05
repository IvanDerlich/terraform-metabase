# Abort on error, unset vars, and failed pipes; print each command before running it
set -euxo pipefail

# Log to ubuntu's home so it's visible on first SSH login
LOG_FILE="/home/ubuntu/build-log-$(date +%Y%m%d_%H%M%S).log"
touch "$LOG_FILE"
# Script runs as root via cloud-init; keep the log readable by ubuntu
chown ubuntu:ubuntu "$LOG_FILE"
# Redirect all stdout/stderr to both the terminal (cloud-init captures it) and the log file
exec > >(tee -i -a "$LOG_FILE") 2>&1

POLL_INTERVAL=0.3
