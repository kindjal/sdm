#! /bin/bash
set -ex
for dir in sdm sdm-disk sdm-rtm sdm-service; do
    cd $dir
    /usr/bin/pdebuild --auto-debsign --debsign-k 1C4CD956
    cd - >/dev/null 2>&1
done
