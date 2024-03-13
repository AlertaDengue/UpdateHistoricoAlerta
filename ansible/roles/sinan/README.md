# Upload SINAN File
This command will export a file into HETZNER, executing the command `upload_sinan`, which inserts the file into "Municipio"."Notificacao"

## Configure Vault Credentials
`vault-config.yaml` needs to be configured if it hasn't been yet:
```
$ makim vault.create-vault-config
```

## Uploading a SINAN file into Database
Variables:
- file-path (required): Absolute path of a file (example: /home/<user>/Downloads/<file>)
- year (required): Notification year in the format YYYY (example: 2024)
- codarea (optional): Area code of the file (default: "BR")
- disease (optional): Disease, options "DEN", "CHIK" or "ZIKA" (default: "DEN")

Basic Command:
```sh
$ makim ansible.upload-sinan-dbf --file-path <file> --year <year>
```

