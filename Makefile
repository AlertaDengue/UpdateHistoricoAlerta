# Makefile
SHELL=/bin/bash

disease:=
yearweek:=

install:
	: # Install virtualven
	sudo apt-get install python3-venv
	sudo apt-get install python3-pip
	sudo pip3 install virtualenv
	python3 -m venv venv

	: # Activate venv and install smthing inside
	source venv/bin/activate && pip install -r requirements.txt

test-venv:
	: # Create venv if it doesn't exist
	: # test -d venv || virtualenv -p python3 --no-site-packages venv
	test -d venv || python3 -m venv venv

create-vault-config:
	: # create variables into yml
	: # ansible vault
	source venv/bin/activate && (\
					ansible-vault create vault-config.yaml \
	)

change-vault-config:
	: # create variables into yml
	: # ansible vault
	source venv/bin/activate && (\
					ansible-vault edit vault-config.yaml \
	)

change-vault-passwd:
	: # create variables into yml
	: # ansible vault
	source venv/bin/activate && (\
					ansible-vault rekey vault-config.yaml \
	)

run:
	: # execute the playbook
	source venv/bin/activate && (\
		ansible-playbook -i hosts --ask-vault-pass --extra-vars '@vault-config.yaml' \
			-e 'yearweek=${yearweek} disease=${disease}' prepare_hosts.yaml --verbose \
	)

history:
	: # viewd history
	source venv/bin/activate && (\
	ansible servers -m command -a "cat /home/infodengue/logs/ansible/uploads_script.alerta.logs" \
	)
