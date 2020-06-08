#!/bin/sh

if [ "$4" == "" ]
then
    echo >&2 "usage: $0 host user pass db"
    exit 1
fi

host="$1"
user="$2"
pass="$3"
db="$4"

v=$(expr $(cd /db/migrations && ls | sort -g | sed 's/_.*$//' | tail -n 1) + 0)
dbv=$(mysql -r -s --skip-column-names -h$host -u$user -p$pass $db -e 'select version + dirty from schema_migrations;')
if [ "$v" -eq "$dbv" ]
then
    echo "schema version matched: \"$v\"(migration scripts) VS \"$dbv\"(DB)"
    exit 0
else
    echo "schema version mis-matched: \"$v\"(migration scripts) VS \"$dbv\"(DB)"
    exit 1
fi
