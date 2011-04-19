#! /bin/bash
set -ex
mkdir -p deploy/bin
for dir in system system-disk/ system-rtm/ system-service/ ; do
    rsync -av $dir/lib/ deploy/lib/
    rsync -av $dir/t/ deploy/t/
done
cp system/bin/system deploy/bin/system
