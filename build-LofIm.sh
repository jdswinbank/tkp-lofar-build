#!/bin/sh

#BUILDROOT=/zfs/heastro-plex/scratch/swinbank/build
BUILDROOT=/var/scratch
LOFARROOT=$BUILDROOT/LOFAR
INSTALLROOT=/opt/LofIm

update_lofar="1"
remove_old=""

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

echo "Configuring."
mkdir -p $LOFARROOT/build/gnu_opt
cd $LOFARROOT/build/gnu_opt
cmake -DCASAREST_ROOT_DIR=/opt/casarest/casarest -DBUILD_SHARED_LIBS=ON -DBUILD_PACKAGES="Offline" -DCMAKE_INSTALL_PREFIX=$INSTALLROOT/lofar-`date +%Y-%m-%d` $LOFARROOT

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
rm $INSTALLROOT/lofar
ln -s $INSTALLROOT/lofar-`date +%Y-%m-%d` $INSTALLROOT/lofar

if [ $remove_old ]
then
    old_date=`date --date="1 month ago" +%Y-%m-%d`
    old_build=$INSTALLROOT/lofar-$old_date
    if [ -d $old_build ]
    then
        echo "Removing build from $old_date."
        rm -rf $old_build
    fi
fi

echo "Using LOFARsoft r$LOFARVER."
echo "Done."
