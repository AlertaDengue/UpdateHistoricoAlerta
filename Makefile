SHELL=/bin/bash
venv_dir := venv
hosts_dir := ansible/config/hosts
playbooks_dir := playbooks
tasks_dir := ansible/roles/maps-upload/tasks
roles_dir := ansible/roles
vault_config := ansible/config/vault-config.yaml

disease :=
yearweek :=

.PHONY: install test-venv create-vault-config change-vault-config change-vault-passwd update-alertas history

install:
	# Install system dependencies
	sudo apt-get update
	sudo apt-get install -y python3-venv python3-pip

	# Create and activate the virtual environment
	python3 -m venv $(venv_dir)
	source $(venv_dir)/bin/activate && pip install -r requirements.txt

test-venv:
	# Create the virtual environment if it doesn't exist
	test -d $(venv_dir) || python3 -m venv $(venv_dir)

create-vault-config:
	# Create the vault configuration file
	source $(venv_dir)/bin/activate && ansible-vault create $(vault_config)

change-vault-config:
	# Edit the vault configuration file
	source $(venv_dir)/bin/activate && ansible-vault edit $(vault_config)

change-vault-passwd:
	# Change the password of the vault configuration file
	source $(venv_dir)/bin/activate && ansible-vault rekey $(vault_config)

update-alertas:
	# Execute the playbook to update alerts
	source $(venv_dir)/bin/activate && \
	ansible-playbook -i $(hosts_dir) --ask-vault-pass \
	--extra-vars "@$(vault_config)" -e "yearweek=$(yearweek) disease=$(disease)" \
	$(playbooks_dir)/prepare_alerta_hosts.yaml

history:
	# View the history
	source $(venv_dir)/bin/activate && \
	ansible servers -m command -a "cat /var/log/ansible/system_update_epiweeks.log"
