#!/bin/sh

BUILDROOT=/var/scratch
CASARESTROOT=$BUILDROOT/casarest
INSTALLROOT=/opt/casarest

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
cd $CASARESTROOT
if [ $update ]
then
    echo "Updating casarest sources."
    git clean -df
    git svn rebase
else
    echo "Not updating casarest sources."
fi
CASAREST_VER=`git svn find-rev HEAD`

echo "Configuring."
mkdir -p $CASARESTROOT/build
cd $CASARESTROOT/build
cmake -DCASACORE_ROOT_DIR=/usr/local -DCMAKE_INSTALL_PREFIX=$INSTALLROOT/casarest-`date +%Y-%m-%d` $CASARESTROOT

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

echo "Updating default symlink."
rm $INSTALLROOT/casarest
ln -s $INSTALLROOT/casarest-`date +%Y-%m-%d` $INSTALLROOT/casarest

if [ $remove_old ]
then
    old_date=`date --date="1 month ago" +%Y-%m-%d`
    old_build=$INSTALLROOT/casarest-$old_date
    if [ -d $old_build ]
    then
        echo "Removing build from $old_date."
        rm -rf $old_build
    fi
fi

echo "Using Casarest r$CASAREST_VER."
echo "Done."
