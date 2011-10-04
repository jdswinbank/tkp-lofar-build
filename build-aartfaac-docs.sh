#!/bin/sh

REPOSITORY=/srv/git/aartfaac/code.git
TREE=HEAD

git archive --prefix=aartfaac-code/ --remote $REPOSITORY $TREE | (cd /tmp && tar xf -)

cd /tmp/aartfaac-code
./bootstrap
cd build
make Documentation
rsync -a --delete doc/html/* /var/www/aartfaac-docs
cd /tmp
rm -rf aartfaac-code
