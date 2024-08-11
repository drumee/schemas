#!/bin/bash
script_path=$0

if [[ $script_path =~ ^\/ ]]; then
  script_dir=$(dirname $script_path)
else 
  if [[ $script_path =~ ^\.\/ ]]; then
    script_path=$(echo $script_path | sed -e "s/^\.//")
    script_dir="$(pwd)$(dirname $script_path)"
  else 
    script_dir=$(pwd)/$(dirname $script_path)
  fi
fi 

cd $script_dir
cd ..

mysqldump --no-data -u $USER template_common > common/templates/common.sql
mysqldump --no-data -u $USER template_hub > hub/templates/hub.sql
mysqldump --no-data -u $USER template_drumate > drumate/templates/drumate.sql