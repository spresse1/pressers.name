#! /bin/bash

source .config

TEMPDIR=$(mktemp -t -d hugogen.XXX)

echo $TEMPDIR

hugo -d "$TEMPDIR"

rsync -r --delete "${TEMPDIR}/" ${USER}@${HOST}:

#rm -rf "${TEMPDIR}"