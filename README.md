# AnsibleToPostgres

This tool is used to copy the local sql script file to the server and update the database
### Commands
#### Install ansible and create environment
```
make install
```
#### Create an encrypted file with variables for connecting to the server
```
make create_passwd
```
*Add your variable keys:*
> simple vault example
```
cluster_sudo_passwd: 123456
cluster_user_name: userhost
psql_user: psqluser
psql_db: psqldatabase
psql_password: psqlpasswd
```
#### How to change encrypted file variables *(if necessary)*
```
make change_passwd
```
####  Run the sql script on the target server
```
make run
```
