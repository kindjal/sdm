#! /bin/bash

set -e

die () {
    echo "Error: $@"
    exit 1
}

trap die ERR

TOP=`pwd`
BASE=$TOP/lib/System/
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
PERL="/usr/bin/perl -I $TOP/lib"
SYSTEM="$PERL $TOP/bin/system"

[ -d $BASE ] || \
    die "./lib/System not found"

[ -x $TOP/bin/system ] || \
    die "./bin/system not found"

# convenience script to "start from scratch"
echo flush sqlite3 DB
rm -f $BASE/DataSource/Disk.sqlite3
rm -f $BASE/DataSource/Disk.sqlite3-dump
rm -f $BASE/DataSource/Disk.sqlite3n
rm -f $BASE/DataSource/Disk.sqlite3n-dump

echo flush and remake Meta
cd ..
rm -f $BASE/DataSource/Meta.sqlite3
rm -f $BASE/DataSource/Meta.sqlite3n
rm -f $BASE/DataSource/Meta.sqlite3-dump
rm -f $BASE/DataSource/Meta.sqlite3n-dump
cd -

echo make new sqlite3 DB
sqlite3 $BASE/DataSource/Disk.sqlite3n < $BASE/DataSource/Disk.sqlite3n-schema
sqlite3 $BASE/DataSource/Disk.sqlite3n .dump > $BASE/DataSource/Disk.sqlite3n-dump

