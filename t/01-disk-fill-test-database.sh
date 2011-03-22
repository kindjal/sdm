#! /bin/bash

set -x
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

. ./t/00-disk-prep-test-database.sh

$SYSTEM disk group list --noheaders --filter name=SYSTEMS 2>/dev/null | grep -q SYSTEMS || \
  $SYSTEM disk group add --name SYSTEMS

$SYSTEM disk group list --noheaders --filter name=INFO_APIPE 2>/dev/null | grep -q INFO_APIPE || \
  $SYSTEM disk group add --name INFO_APIPE

$SYSTEM disk filer list --noheaders --filter name=nfs11 2>/dev/null | grep -q nfs11 || \
  $SYSTEM disk filer add --name nfs11

$SYSTEM disk filer list --noheaders --filter name=nfs12 2>/dev/null | grep -q nfs12 || \
  $SYSTEM disk filer add --name nfs12

$SYSTEM disk host list --noheaders --filter hostname=nfs11 2>/dev/null | grep -q nfs11 || \
  $SYSTEM disk host add --hostname nfs11

$SYSTEM disk array list --noheaders --filter name=GCEVA3 2>/dev/null | grep -q GCEVA3 || \
  $SYSTEM disk array add --name GCEVA3

$SYSTEM disk array list --noheaders --filter name=GCEVA2 2>/dev/null | grep -q GCEVA2 || \
  $SYSTEM disk array add --name GCEVA2

$SYSTEM disk volume list --noheaders --filter filer=nfs11 2>/dev/null | grep -q sata821 || \
  $SYSTEM disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896 --filername nfs11 --physical-path=/vol/sata821 --disk-group=SYSTEMS

$SYSTEM disk volume list --noheaders --filter filer=nfs11 2>/dev/null | grep -q sata822 || \
  $SYSTEM disk volume add --mount-path=/gscmnt/sata822 --total-kb=6438990688 --used-kb=5722964896 --filername nfs11 --physical-path=/vol/sata822 --disk-group=SYSTEMS

$SYSTEM disk volume list --noheaders --filter filer=nfs12 2>/dev/null | grep -q sata821 || \
  $SYSTEM disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896 --filername nfs12 --physical-path=/vol/sata821 --disk-group=SYSTEMS

$SYSTEM disk volume list --noheaders --filter filer=nfs12 2>/dev/null | grep -q sata823 || \
  $SYSTEM disk volume add --mount-path=/gscmnt/sata823 --total-kb=6438990688 --used-kb=5722964896 --filername nfs12 --physical-path=/vol/sata823 --disk-group=INFO_APIPE

