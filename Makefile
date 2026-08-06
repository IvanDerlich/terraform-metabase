SHELL := /bin/bash
export TF_DATA_DIR=../tf-data

.PHONY: help check-env init plan output apply destroy fmt apply-auto apply-autoapprove apply-autoaprove destroy-auto destroy-autoapprove destroy-autoaprove restart test logs-db logs-app logs-fe logs-all

help:
	@echo make init
	@echo make plan
	@echo make apply
	@echo make apply-autoapprove
	@echo make apply-auto
	@echo make output
	@echo make destroy
	@echo make destroy-autoapprove
	@echo make destroy-auto
	@echo make restart
	@echo make logs-db
	@echo make logs-app
	@echo make logs-fe
	@echo make logs-all

check-env:
	env | grep OS_

init plan output apply destroy fmt:
	tofu $@

apply-auto:
	tofu apply --auto-approve

apply-autoapprove:
	tofu apply --auto-approve

apply-autoaprove: apply-autoapprove

destroy-auto:
	tofu destroy --auto-approve

destroy-autoapprove:
	tofu destroy --auto-approve

destroy-autoaprove: destroy-autoapprove

restart: destroy-autoapprove apply-autoapprove

test:
	tofu test

logs-db:
	@set -euo pipefail; \
	cmd="$$(tofu output -raw ssh_db_cmd)"; \
	echo "[db] waiting for cloud-init and streaming logs"; \
	eval "$$cmd 'sudo cloud-init status --wait || true; sudo tail -n +1 -F /var/log/cloud-init-output.log'"

logs-app:
	@set -euo pipefail; \
	cmd="$$(tofu output -raw ssh_app_cmd)"; \
	echo "[app] waiting for cloud-init and streaming logs"; \
	eval "$$cmd 'sudo cloud-init status --wait || true; sudo tail -n +1 -F /var/log/cloud-init-output.log'"

logs-fe:
	@set -euo pipefail; \
	cmd="$$(tofu output -raw ssh_fe_cmd)"; \
	echo "[fe] waiting for cloud-init and streaming logs"; \
	eval "$$cmd 'sudo cloud-init status --wait || true; sudo tail -n +1 -F /var/log/cloud-init-output.log'"

logs-all:
	@set -euo pipefail; \
	( $(MAKE) --no-print-directory logs-db 2>&1 | sed -u 's/^/[db] /' ) & pid_db=$$!; \
	( $(MAKE) --no-print-directory logs-app 2>&1 | sed -u 's/^/[app] /' ) & pid_app=$$!; \
	( $(MAKE) --no-print-directory logs-fe 2>&1 | sed -u 's/^/[fe] /' ) & pid_fe=$$!; \
	trap 'kill $$pid_db $$pid_app $$pid_fe 2>/dev/null || true' INT TERM EXIT; \
	wait