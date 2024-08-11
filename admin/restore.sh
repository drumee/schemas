#!/bin/bash


for arg in "$@"
do
	case $arg in
		-f=*|--from=*)
			src_dir="${arg#*=}"
			shift
			;;
		-t=*|--to=*)
			to="${arg#*=}"
			shift
      ;;
	esac
done

cd $src_dir
for f in `ls`; do 
  dbname=$(echo $f | sed -e "s/\.sql//"); 
  echo Restoring $dbname; 
  mysql -e "CREATE DATABASE IF NOT EXISTS $dbname"
  mysql -u $USER --database $dbname -h localhost  < $f
done