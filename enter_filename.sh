#!/bin/bash

# Prompts the variables for filename and
# set linux environment variables to playbook ansible

DATE=`date`
echo "Date is $DATE"

mkdir -p /tmp/sql

read -p "Disease: " DISEASE
read -p "Epidemic YearWeek: " YEARWEEK

echo DISEASE=${DISEASE} > .var_file_names
echo YEARWEEK=${YEARWEEK} >> .var_file_names

for file in sql/*${DISEASE}.sql
do
  cp "$file" "/tmp/${file/${DISEASE}.sql/update_hist_alerta_${YEARWEEK}_${DISEASE}.sql}"
  echo -e "Successfully renamed the file!"
done

echo -e "update_hist_alerta_${YEARWEEK}_${DISEASE}.sql work in progress.. \n"
