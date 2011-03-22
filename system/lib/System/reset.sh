#!/bin/sh
set -e
# convenience script to "start from scratch"
echo flush sqlite3 DB
rm -f DataSource/Disk.sqlite3
rm -f DataSource/Disk.sqlite3-dump
rm -f DataSource/Disk.sqlite3n
rm -f DataSource/Disk.sqlite3n-dump

echo flush and remake Meta
cd ..
rm -f System/DataSource/Meta.sqlite3
rm -f System/DataSource/Meta.sqlite3n
rm -f System/DataSource/Meta.sqlite3-dump
rm -f System/DataSource/Meta.sqlite3n-dump
cd -

echo make new sqlite3 DB
sqlite3 DataSource/Disk.sqlite3n < DataSource/Disk.sqlite3n-schema
sqlite3 DataSource/Disk.sqlite3n .dump > DataSource/Disk.sqlite3n-dump

