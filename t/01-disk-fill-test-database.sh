#! /bin/bash
set -x

. ./t/00-disk-prep-test-database.sh

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
  $SYSTEM disk volume add --mount-path=/gscmnt/sata821 --total-kb=6438990688 --used-kb=5722964896

$SYSTEM disk volume list --noheaders --filter filer=nfs12 2>/dev/null | grep -q sata821 || \
  $SYSTEM disk volume add --mount-path=/gscmnt/gc2000 --total-kb=16438990688 --used-kb=5722964896

$SYSTEM disk group list --noheaders --filter name=PRODUCTION_SOLID 2>/dev/null | grep -q PRODUCTION_SOLID || \
  $SYSTEM disk group add --name PRODUCTION_SOLID --permissions 755 --sticky 0 --unix-uid 12376 --unix-gid 10001

