#! /bin/bash

set -e

die () {
    echo "Error: $!"
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

$SYSTEM disk filer list --noheaders --filter name=nfs11 2>/dev/null | grep -q nfs11 || \
  $SYSTEM disk filer add --name nfs11

$SYSTEM disk filer list --noheaders --filter name=nfs12 2>/dev/null | grep -q nfs12 || \
  $SYSTEM disk filer add --name nfs12

$SYSTEM disk host list --noheaders --filter hostname=nfs11 2>/dev/null | grep -q nfs11 || \
  $SYSTEM disk host add --hostname nfs11 --filer nfs11

$SYSTEM disk array list --noheaders --filter name=GCEVA3 2>/dev/null | grep -q GCEVA3 || \
  $SYSTEM disk array add --name GCEVA3 --host nfs11

$SYSTEM disk array list --noheaders --filter name=GCEVA2 2>/dev/null | grep -q GCEVA2 || \
  $SYSTEM disk array add --name GCEVA2 --host nfs11

$SYSTEM disk volume list --noheaders --filter filer=nfs11 2>/dev/null | grep -q sata821 || \
  $SYSTEM disk volume add --filer=nfs11 --mount-path=/gscmnt/sata821 --physical-path=/vol/sata821 --total-kb=6438990688 --used-kb=5722964896

$SYSTEM disk volume list --noheaders --filter filer=nfs12 2>/dev/null | grep -q sata821 || \
  $SYSTEM disk volume add --filer=nfs12 --mount-path=/gscmnt/gc2000 --physical-path=/vol/gc2000 --total-kb=16438990688 --used-kb=5722964896

$SYSTEM disk group list --noheaders --filter name=PRODUCTION_SOLID 2>/dev/null | grep -q PRODUCTION_SOLID || \
  $SYSTEM disk group add --name PRODUCTION_SOLID --permissions 755 --sticky 0 --unix-uid 12376 --unix-gid 10001

