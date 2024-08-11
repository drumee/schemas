#!/bin/bash


for arg in "$@"
do
	case $arg in
		-f=*|--from=*)
			src_dir="${arg#*=}"
			shift
      ;;
		-t=*|--to=*)
			dbname="${arg#*=}"
			shift
      ;;
	esac
done
usage(){
	echo "Usage : $0 --dbname=* script"
	exit 1
}

if [ -z $dbname ]; then 
	usage
fi 

echo "Selecting DB $dbname"
if [ -z $src_dir ]; then 
	list=$@
	dir=.
else 
	list=$(ls $src_dir/*.sql)
	dir=$src_dir
fi 

#cd $dir 

for f in $list; do 
  echo "   [Loading script] .....  $f"; 
	mysql -u $USER --database $dbname -h localhost  < $f
  # mysql -e "CREATE DATABASE IF NOT EXISTS $dbname"
  # mysql -u $USER --database $dbname -h localhost  < $f
done