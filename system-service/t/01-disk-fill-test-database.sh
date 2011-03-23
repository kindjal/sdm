#! /bin/bash

set -x
set -e

die () {
    echo "Error: $@"
    exit 1
}

trap die ERR

TOP=`pwd`
BASE=$TOP/lib/System
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
PERL="/usr/bin/perl -I $TOP/lib -I ../system/lib -I ../system-*/lib"
SYSTEM="$TOP/../system/bin/system"

[ -d $BASE ] || \
    die "$BASE not found"
[ -x $SYSTEM ] || \
    die "$SYSTEM not found"

. ./t/00-disk-prep-test-database.sh

$PERL $SYSTEM disk group list --noheaders --filter name=SYSTEMS 2>/dev/null | grep -q SYSTEMS || \
  $PERL $SYSTEM disk group add --name SYSTEMS

$PERL $SYSTEM disk group list --noheaders --filter name=INFO_APIPE 2>/dev/null | grep -q INFO_APIPE || \
  $PERL $SYSTEM disk group add --name INFO_APIPE

$PERL $SYSTEM disk filer list --noheaders --filter name=nfs11 2>/dev/null | grep -q nfs11 || \
  $PERL $SYSTEM disk filer add --name nfs11

$PERL $SYSTEM disk filer list --noheaders --filter name=nfs12 2>/dev/null | grep -q nfs12 || \
  $PERL $SYSTEM disk filer add --name nfs12

$PERL $SYSTEM disk host list --noheaders --filter hostname=nfs11 2>/dev/null | grep -q nfs11 || \
  $PERL $SYSTEM disk host add --hostname nfs11

$PERL $SYSTEM disk array list --noheaders --filter name=GCEVA3 2>/dev/null | grep -q GCEVA3 || \
  $PERL $SYSTEM disk array add --name GCEVA3

$PERL $SYSTEM disk array list --noheaders --filter name=GCEVA2 2>/dev/null | grep -q GCEVA2 || \
  $PERL $SYSTEM disk array add --name GCEVA2

$PERL $SYSTEM disk volume list --noheaders --filter filer=nfs11 2>/dev/null | grep -q sata821 || \
  $PERL $SYSTEM disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896 --filername nfs11 --physical-path=/vol/sata821 --disk-group=SYSTEMS

$PERL $SYSTEM disk volume list --noheaders --filter filer=nfs11 2>/dev/null | grep -q sata822 || \
  $PERL $SYSTEM disk volume add --mount-path=/gscmnt/sata822 --total-kb=6438990688 --used-kb=5722964896 --filername nfs11 --physical-path=/vol/sata822 --disk-group=SYSTEMS

$PERL $SYSTEM disk volume list --noheaders --filter filer=nfs12 2>/dev/null | grep -q sata821 || \
  $PERL $SYSTEM disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896 --filername nfs12 --physical-path=/vol/sata821 --disk-group=SYSTEMS

$PERL $SYSTEM disk volume list --noheaders --filter filer=nfs12 2>/dev/null | grep -q sata823 || \
  $PERL $SYSTEM disk volume add --mount-path=/gscmnt/sata823 --total-kb=6438990688 --used-kb=5722964896 --filername nfs12 --physical-path=/vol/sata823 --disk-group=INFO_APIPE

