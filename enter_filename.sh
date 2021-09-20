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

echo -e "Updated variable names ! \n"
