#!/bin/sh
# convenience script to "start from scratch"
#cd ..
#rm -f System.pm System/DataSource/Meta.* && ur define namespace System
#cd -
sqlite3 Disk.sqlite3 < disk-schema.txt
sqlite3 Disk.sqlite3 .dump > Disk.sqlite3-dump
# Fix FK column issues with sqlite3.  This is a known URism.
perl -pi -e ' if ( /dd_fk_constraint_column/../\)/sgm ) { s/owner varchar.*/owner varchar,/};' DataSource/Meta.sqlite3-dump
ur update classes-from-db
#
./system disk filer create --name nfs10home
