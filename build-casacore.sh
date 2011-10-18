#!/bin/sh

BUILDROOT=/var/scratch
CASACOREROOT=$BUILDROOT/casacore
INSTALLROOT=/opt

update="1"
remove_old=""

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
else
    echo "Not updating casarest sources."
fi
CASACORE_VER=`git svn find-rev HEAD`
if [ -d $INSTALLROOT/archive/casacore/r$CASACORE_VER ]
then
    echo "Already at the latest version."
    exit 0
fi

echo "Configuring."
mkdir -p $CASACOREROOT/build/opt
cd $CASARESTROOT/build/opt
cmake -DCMAKE_INSTALL_PREFIX=/$INSTALLROOT/archive/casacore/r$CASACORE_VER -DUSE_HDF5=OFF -DWCSLIB_ROOT_DIR=/opt/wcslib -DWCSLIB_INCLUDE_DIR=/opt/wcslib/include -DWCSLIB_LIBRARY=/opt/wcslib/lib/libwcs.so -DDATA_DIR=/opt/measures/data ../..

echo "Building."
make -j8
result=$?
if [ $result -ne 0 ]
then
    echo "Build failed! (Returned value $result)."
    exit 1
fi

echo "Installing."
make install
result=$?
if [ $result -ne 0 ]
then
    echo "Installation failed! (Returned value $result)."
    exit 1
fi

echo "Updating default symlink."
rm $INSTALLROOT/casacore
ln -s $INSTALLROOT/archive/casacore/r$CASACORE_VER $INSTALLROOT/casacore

echo "Using casacore r$CASAREST_VER."
echo "Done."
