#!/bin/bash

# We want to build and install:
#
# - All tags into /opt/tkp/<tagname>/
# - The HEAD of the master branch into /opt/tkp/nightly/[sha1]/

SOURCE_DIR=/var/scratch/tkp
TARGET_DIR=/opt/tkp

generate_initfile() {
    DESTINATION=${1}
    INITFILE=${DESTINATION}/init.sh

cat > $INITFILE <<-END
export LD_LIBRARY_PATH=${DESTINATION}/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export PATH=${DESTINATION}/bin${PATH:+:${PATH}}
export PYTHONPATH=/opt/archive/python-monetdb/default/lib/python2.7/site-packages:${DESTINATION}/lib/python2.7/site-packages${PYTHONPATH:+:${PYTHONPATH}}
END
}

build_and_install() {
    TREEISH=${1}
    DESTINATION=${2}
    if [ ! -e ${DESTINATION} ]
    then
        echo "Will build and install ${TREEISH} to ${DESTINATION}"
        cd ${SOURCE_DIR}
        git clean -dfx
        git checkout ${TREEISH}
        mkdir build && cd build
        cmake -DCMAKE_INSTALL_PREFIX=${DESTINATION} -DPYTHON_PACKAGES_DIR=${DESTINATION}/lib/python2.7/site-packages/ ..
        make
        make install
        generate_initfile ${DESTINATION}
    fi
}

failure() {
    echo ${BASH_COMMAND} | mail -s "TKP build failure on heastro1" jds
    exit 1
}

trap failure ERR

# First, change to the source directory, clean up, and fetch the latest
# version.

cd ${SOURCE_DIR}
git checkout master
git pull

# Now we will build all the tags
for tag in `git tag`
do
    DESTINATION=${TARGET_DIR}/${tag}
    build_and_install ${tag} ${DESTINATION}
done

# Now the latest master
cd ${SOURCE_DIR}
latest_sha1=`git show --oneline -s master | cut -d\  -f1`
DESTINATION=${TARGET_DIR}/nightly/${latest_sha1}
build_and_install master ${DESTINATION}
rm -f ${TARGET_DIR}/nightly/init.sh && ln -s ${DESTINATION}/init.sh ${TARGET_DIR}/nightly/init.sh
