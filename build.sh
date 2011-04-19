#! /bin/bash
set -ex
for dir in system system-disk system-rtm system-service; do
    cd $dir
    /usr/bin/pdebuild --auto-debsign --debsign-k 1C4CD956
    cd - >/dev/null 2>&1
done
