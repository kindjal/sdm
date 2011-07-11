#! /bin/bash
set -ex
mkdir -p deploy/bin
for dir in sdm sdm-*; do
    [ -d $dir/lib ] && \
      rsync -av --exclude '*.sqlite3n' $dir/lib/ deploy/lib/
    [ -d $dir/t ] && \
      rsync -av $dir/t/ deploy/t/
done
cp sdm/bin/sdm deploy/bin/sdm
