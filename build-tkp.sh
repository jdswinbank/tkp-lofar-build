#!/bin/bash

# Target directory for installation
BUILD_DATE=`date +%F-%H-%M`
TARGET=/opt/tkp/${BUILD_DATE}
echo "Installing into $TARGET"

TKP_SOURCE_DIR=/var/scratch/tkp
TRAP_SOURCE_DIR=/var/scratch/trap

failure() {
    echo ${BASH_COMMAND} | mail -s "TKP build failure on heastro1" jds
    exit 1
}

trap failure ERR

update_git_source() {
    [ ${1} ] && BRANCH=${1} || BRANCH="master"

    git clean -dfx
    git checkout -f ${BRANCH}
    git pull
    git tag daily-build-${BUILD_DATE}
}

build_and_install() {
    SOURCE=${1}
    DESTINATION=${2}

    cd ${SOURCE}
    update_git_source
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=${DESTINATION} ..
    make
    make install
}

build_and_install ${TKP_SOURCE_DIR} ${TARGET}
build_and_install ${TRAP_SOURCE_DIR} ${TARGET}
rm -f /opt/tkp/latest && ln -s ${TARGET} /opt/tkp/latest
