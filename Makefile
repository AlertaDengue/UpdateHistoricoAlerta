# Makefile
SHELL=/bin/bash
include .var_file_names
export


all: install create_passwd run

install: venv
	: # Install virtualven
	sudo apt-get install python3-venv
	sudo apt-get install python3-pip
	sudo pip3 install virtualenv
	python3 -m venv venv

	: # Activate venv and install smthing inside
	source venv/bin/activate && pip install -r requirements.txt

test_venv:
	: # Create venv if it doesn't exist
	: # test -d venv || virtualenv -p python3 --no-site-packages venv
	test -d venv || python3 -m venv venv

create_passwd:
	: # create variables into yml
	: # ansible vault
	source venv/bin/activate && (\
					ansible-vault create passwd.yml \
	)

change_passwd:
	: # create variables into yml
	: # ansible vault
	source venv/bin/activate && (\
					ansible-vault rekey passwd.yml \
	)

set_file_names:
	: # create directories and copy script
	: # set +o allexport
	./enter_filename.sh

# First run get_file_names to create the file variable names
run: set_file_names
	: # execute the playbook
	source venv/bin/activate && (\
	ansible-playbook -i hosts --ask-vault-pass --extra-vars '@passwd.yml' db-server-playbook.yml --verbose \
	)

history:
	: # viewd history
	source venv/bin/activate && (\
	ansible servers -m command -a "cat /home/infodengue/logs/ansible/uploads_script.alerta.logs" \
	)
