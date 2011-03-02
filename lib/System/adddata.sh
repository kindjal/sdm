#!/bin/sh

set -e
set -x

./system disk filer list --noheaders --filter name=localhost 2>/dev/null | grep -q localhost || \
  ./system disk filer create --name localhost

./system disk host list --noheaders --filter hostname=localhost 2>/dev/null | grep -q localhost || \
  ./system disk host create --hostname localhost --filer localhost

./system disk array list --noheaders --filter name=localdisk 2>/dev/null | grep -q localdisk || \
  ./system disk array create --name localdisk --host localhost

./system disk volume list --noheaders --filter filer=localdisk 2>/dev/null | grep -q localhost || \
  ./system disk volume create --filer=localhost --mount-path=/ --physical-path=/dev/sda1 --total-kb=19737268 --used-kb=7915612

./system disk group list --noheaders --filter name=mine 2>/dev/null | grep -q mine || \
  ./system disk group create --name mine --permissions 755 --sticky 0 --unix-uid 12376 --unix-gid 10001
