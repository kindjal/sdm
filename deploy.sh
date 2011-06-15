#! /bin/bash
set -ex
mkdir -p deploy/bin
for dir in sdm sdm-*; do
    rsync -av $dir/lib/ deploy/lib/
    rsync -av $dir/t/ deploy/t/
done
cp sdm/bin/sdm deploy/bin/sdm
