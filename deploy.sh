#! /bin/bash
set -ex
mkdir -p deploy/bin
for dir in sdm sdm-disk/ sdm-rtm/ sdm-service/ ; do
    rsync -av $dir/lib/ deploy/lib/
    rsync -av $dir/t/ deploy/t/
done
cp sdm/bin/sdm deploy/bin/sdm
