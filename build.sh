#!/bin/sh

BUILDROOT=/zfs/heastro-plex/scratch/swinbank/build
LOFARROOT=$BUILDROOT/LOFAR
ASKAPROOT=$BUILDROOT/askapsoft

update_askap="1"
update_lofar="1"

while getopts al optionName
do
    case $optionName in
        a) update_askap="";;
        l) update_lofar="";;
        \?) exit 1;;
    esac
done

# Update ASKAP sources
if [ $update_askap ]
then
    echo "Updating ASKAP sources."
    rsync -tvr lfe001:/opt/LofIm/daily/askapsoft/trunk/ $ASKAPROOT
    cd $ASKAPROOT
    svn st | awk '{print $2}' | xargs rm -rf
else
    echo "Not updating ASKAP sources."
fi
ASKAPVER=`svn info $ASKAPROOT | grep Revision | cut -d\  -f2`

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

echo "Adding symlinks."
ln -s $ASKAPROOT/Code/Base/accessors/current $LOFARROOT/CEP/Imager/ASKAPsoft/Base/accessors/src
ln -s $ASKAPROOT/Code/Base/askap/current $LOFARROOT/CEP/Imager/ASKAPsoft/Base/askap/src
ln -s $ASKAPROOT/Code/Base/mwbase/askapparallel/current $LOFARROOT/CEP/Imager/ASKAPsoft/Base/mwbase/askapparallel/src
ln -s $ASKAPROOT/Code/Base/mwbase/mwcommon/current $LOFARROOT/CEP/Imager/ASKAPsoft/Base/mwbase/mwcommon/src
ln -s $ASKAPROOT/Code/Base/scimath/current $LOFARROOT/CEP/Imager/ASKAPsoft/Base/scimath/src
ln -s $ASKAPROOT/Code/Components/Synthesis/synthesis/current $LOFARROOT/CEP/Imager/ASKAPsoft/Components/Synthesis/synthesis/src

echo "Configuring."
mkdir -p $LOFARROOT/build/gnu_opt
cd $LOFARROOT/build/gnu_opt
cmake -DBUILD_SHARED_LIBS=ON -DBUILD_PACKAGES="Offline" -DCMAKE_INSTALL_PREFIX=/opt/LofIm/lofar-`date +%Y-%m-%d` $LOFARROOT

echo "Building."
make -j
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
rm /opt/LofIm/lofar
ln -s /opt/LofIm/lofar-`date +%Y-%m-%d` /opt/LofIm/lofar

old_date=`date --date="1 month ago" +%Y-%m-%d`
old_build=/opt/LofIm/lofar-$old_date
if [ -d $old_build ]
then
    echo "Removing build from $old_date."
    rm -rf $old_build
fi
echo "Using ASKAPsoft r$ASKAPVER."
echo "Using LOFARsoft r$LOFARVER."
echo "Done."
