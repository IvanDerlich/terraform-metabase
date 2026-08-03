SHELL := /bin/bash
export TF_DATA_DIR=../tf-data

help:
	@echo make init
	@echo make plan
	@echo make apply
	@echo make output
	@echo make destroy

check-env:
	env | grep OS_

init plan output apply destroy fmt:
	tofu $@

apply-auto:
	tofu apply --auto-approve

destroy-auto:
	tofu destroy --auto-approve

test:
	tofu test