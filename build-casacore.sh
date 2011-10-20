#!/bin/sh

BUILDROOT=/var/scratch
CASACOREROOT=$BUILDROOT/casacore
INSTALLROOT=/opt
#REVISION=21123

update="1"

. `dirname ${0}`/utils.sh

install_symlink() {
    echo "Updating default symlink."
    rm $INSTALLROOT/archive/casacore/default
    ln -s $INSTALLROOT/archive/casacore/r$1 $INSTALLROOT/archive/casacore/default
    echo "Using casacore r$1."
}


while getopts al optionName
do
    case $optionName in
        l) update="";;
        \?) exit 1;;
    esac
done

# Update source
cd $CASACOREROOT
if [ $update ]
then
    echo "Updating casacore sources."
    git clean -df
    git svn rebase
    if [ $REVISION ]
    then
        echo "Checking out r$REVISION."
        git checkout `git svn find-rev r$REVISION`
    fi
else
    echo "Not updating casarest sources."
fi
CASACORE_VER=`git svn find-rev HEAD`
if [ -d $INSTALLROOT/archive/casacore/r$CASACORE_VER ]
then
    echo "Requested build already available."
    install_symlink $CASACORE_VER
    echo "Done."
    exit 0
fi

echo "Configuring."
mkdir -p $CASACOREROOT/build/opt
cd $CASACOREROOT/build/opt
cmake -DCMAKE_INSTALL_PREFIX=/$INSTALLROOT/archive/casacore/r$CASACORE_VER -DUSE_HDF5=OFF -DWCSLIB_ROOT_DIR=/opt/wcslib -DWCSLIB_INCLUDE_DIR=/opt/wcslib/include -DWCSLIB_LIBRARY=/opt/wcslib/lib/libwcs.so -DDATA_DIR=/opt/measures/data ../..

echo "Building."
make -j8
check_result "casacore" "make" $?

echo "Installing."
make install
check_result "casacore" "make install" $?

install_symlink $CASACORE_VER

echo "Done."
