#!/bin/sh

BUILDROOT=/var/scratch
CASARESTROOT=$BUILDROOT/casarest
INSTALLROOT=/opt

update="1"

install_symlink() {
    echo "Updating default symlink."
    rm $INSTALLROOT/archive/casarest/default
    ln -s $INSTALLROOT/archive/casarest/r$1 $INSTALLROOT/archive/casarest/default
    echo "Using casarest r$1."
}

while getopts al optionName
do
    case $optionName in
        l) update="";;
        \?) exit 1;;
    esac
done

# Update source
cd $CASARESTROOT
if [ $update ]
then
    echo "Updating casarest sources."
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
CASAREST_VER=`git svn find-rev HEAD`
if [ -d $INSTALLROOT/archive/casarest/r$CASAREST_VER ]
then
    echo "Already at the latest version."
    install_symlink $CASAREST_VER
    echo "Done."
    exit 0
fi

echo "Configuring."
mkdir -p $CASARESTROOT/build
cd $CASARESTROOT/build
cmake -DWCSLIB_INCLUDE_DIR=/opt/wcslib/include -DWCSLIB_LIBRARY=/opt/wcslib/lib/libwcs.so -DCASACORE_ROOT_DIR=/opt/casacore -DCMAKE_INSTALL_PREFIX=$INSTALLROOT/archive/casarest/r$CASAREST_VER $CASARESTROOT

echo "Building."
make -j8
result=$?
if [ $result -ne 0 ]
then
    echo "Build failed! (Returned value $result)"
    exit 1
fi

echo "Installing."
make install
result=$?
if [ $result -ne 0 ]
then
    echo "Installation failed! (Returned value $result)"
    exit 1
fi

install_symlink $CASAREST_VER

echo "Done."
