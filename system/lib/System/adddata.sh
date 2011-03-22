#!/bin/sh

set -e
set -x

./system disk filer list --noheaders --filter name=nfs11 2>/dev/null | grep -q nfs11 || \
  ./system disk filer create --name nfs11

./system disk host list --noheaders --filter hostname=nfs11 2>/dev/null | grep -q nfs11 || \
  ./system disk host create --hostname nfs11 --filer nfs11

./system disk array list --noheaders --filter name=GCEVA3 2>/dev/null | grep -q GCEVA3 || \
  ./system disk array create --name GCEVA3 --host nfs11

./system disk volume list --noheaders --filter filer=nfs11 2>/dev/null | grep -q sata821 || \
  ./system disk volume create --filer=nfs11 --mount-path=/gscmnt/sata821 --physical-path=/vol/sata821 --total-kb=6438990688 --used-kb=5722964896

./system disk group list --noheaders --filter name=PRODUCTION_SOLID 2>/dev/null | grep -q PRODUCTION_SOLID || \
  ./system disk group create --name PRODUCTION_SOLID --permissions 755 --sticky 0 --unix-uid 12376 --unix-gid 10001
