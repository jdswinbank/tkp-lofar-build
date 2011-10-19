#!/bin/sh

#BUILDROOT=/zfs/heastro-plex/scratch/swinbank/build
BUILDROOT=/var/scratch
LOFARROOT=$BUILDROOT/LOFAR
INSTALLROOT=/opt

update_lofar="1"

install_symlink() {
    echo "Updating default symlink."
    rm $INSTALLROOT/archive/lofim/default
    ln -s $INSTALLROOT/archive/lofim/r$1 $INSTALLROOT/archive/lofim/default
    echo "Using casacore r$1."
}

while getopts al optionName
do
    case $optionName in
        l) update_lofar="";;
        \?) exit 1;;
    esac
done

# Update LOFAR sources
cd $LOFARROOT
if [ $update_lofar ]
then
    echo "Updating LOFAR sources."
    git clean -df
    git svn rebase
    if [ $REVISION ]
    then
        echo "Checking out r$REVISION."
        git checkout `git svn find-rev r$REVISION`
    fi
else
    echo "Not updating LOFAR sources."
fi
LOFARVER=`git svn find-rev HEAD`

# Grab the version of ASKAPsoft used in the previous day's daily build on the
# LOFAR cluster.
echo "Inserting external ASKAPsoft dependencies."
CLUSTERBUILD=`date --date="yesterday" +%a`
for path in Base/accessors/src \
    Base/askap/src \
    Base/mwcommon/src \
    Base/scimath/src \
    Components/Synthesis/synthesis/src
do
  rsync -tvvr --exclude=.svn lfe001:/opt/LofIm/daily/$CLUSTERBUILD/lofar/LOFAR/CEP/Imager/ASKAPsoft/$path/ $LOFARROOT/CEP/Imager/ASKAPsoft/$path
done

if [ -d $INSTALLROOT/archive/lofim/r$LOFARVER ]
then
    echo "Requested build already available."
    install_symlink $LOFARVER
    echo "Done."
    exit 0
fi

echo "Configuring."
mkdir -p $LOFARROOT/build/gnu_opt
cd $LOFARROOT/build/gnu_opt
cmake -DCASACORE_ROOT_DIR=/opt/casacore -DWCSLIB_ROOT_DIR=/opt/wcslib -DCASAREST_ROOT_DIR=/opt/casarest -DBUILD_SHARED_LIBS=ON -DBUILD_PACKAGES="Offline" -DCMAKE_INSTALL_PREFIX=$INSTALLROOT/archive/lofim/r$LOFARVER $LOFARROOT

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

install_symlink $LOFARVER

echo "Done."
