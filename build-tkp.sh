#!/bin/bash

# Target directory for installation
BUILD_DATE=`date +%F-%H-%M`
MASTER_TARGET=/opt/tkp/${BUILD_DATE}-master
CYCLE0_TARGET=/opt/tkp/${BUILD_DATE}-cycle0
echo "Installing master into ${MASTER_TARGET}"
echo "Installing cycle0 into ${CYCLE0_TARGET}"

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
    git tag ${BRANCH}-daily-build-${BUILD_DATE}
}

build_and_install() {
    SOURCE=${1}
    DESTINATION=${2}
    [ ${3} ] && BRANCH=${3} || BRANCH="master"


    cd ${SOURCE}
    update_git_source ${BRANCH}
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=${DESTINATION} -DPYTHON_PACKAGES_DIR=${DESTINATION}/lib/python2.7/site-packages/ ..
    make
    make install
}

# On the current master, everythign is included in one repository
build_and_install ${TKP_SOURCE_DIR} ${MASTER_TARGET} master
rm -f /opt/tkp/latest && ln -s ${MASTER_TARGET} /opt/tkp/latest

# But for cycle0, we need both the trap and tkp repositories
build_and_install ${TKP_SOURCE_DIR} ${CYCLE0_TARGET} cycle0
build_and_install ${TRAP_SOURCE_DIR} ${CYCLE0_TARGET} master
rm -f /opt/tkp/cycle0 && ln -s ${CYCLE0_TARGET} /opt/tkp/cycle0
