# Makefile

all: install run

install: venv
	: # install virtualven
	sudo apt-get install python3-pip
	sudo pip3 install virtualenv

	: # Activate venv and install smthing inside
	. venv/bin/activate && pip install -r requirements.txt

venv:
	: # Create venv if it doesn't exist
	: # test -d venv || virtualenv -p python3 --no-site-packages venv
	test -d venv || python3 -m venv venv

create_passwd:
	: # create variables into yml
	: # ansible vault 
	. venv/bin/activate && (\
                ansible-vault create passwd.yml \

run:
	: # commands
	. venv/bin/activate && (\
		ansible-playbook -i hosts --ask-vault-pass --extra-vars '@passwd.yml' db-server-playbook.yml \
	)
