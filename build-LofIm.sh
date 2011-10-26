#!/bin/sh

LOFARROOT=/var/scratch/LOFAR
INSTALLROOT=/opt

UPDATE="1"

. `dirname ${0}`/utils.sh

install_symlink() {
    echo "Updating default symlink."
    rm $INSTALLROOT/archive/lofim/default
    ln -s $2 $INSTALLROOT/archive/lofim/default
    echo "Using LofIm r$1."
}

# -l          -- update sources
# -r <number> -- use specific revision
# -f          -- force build, even if specified version already exists
# -d          -- install this as default option
# -s          -- suffix for install directory
while getopts lr:s:fd optionName
do
    case $optionName in
        l) UPDATE="";;
        r) REVISION=$OPTARG;;
        s) SUFFIX=$OPTARG;;
        f) FORCE=1;;
        d) DEFAULT=1;;
        \?) exit 1;;
    esac
done

# Update LOFAR sources
cd $LOFARROOT
if [ $UPDATE ]
then
    echo "Updating LOFAR sources."
    git stash
    git clean -df
    git svn rebase
    if [ $REVISION ]
    then
        echo "Checking out r$REVISION."
        git checkout `git svn find-rev r$REVISION`
    fi
    git stash pop
else
    echo "Not updating LOFAR sources."
fi

LOFARVER=`git svn find-rev HEAD`
INSTALL_DIRECTORY=$INSTALLROOT/archive/lofim/r$LOFARVER${SUFFIX:+-${SUFFIX}}

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
  rsync -tvvr --exclude=.svn \
  lfe001:/opt/LofIm/daily/$CLUSTERBUILD/lofar/LOFAR/CEP/Imager/ASKAPsoft/$path/ \
  $LOFARROOT/CEP/Imager/ASKAPsoft/$path
done

# Only build if either -f was specified or the destination doesn't exist
if [ $FORCE ] || [ ! -d $INSTALL_DIRECTORY ]
then
  echo "Configuring."
  mkdir -p $LOFARROOT/build/gnu_opt
  cd $LOFARROOT/build/gnu_opt
        #-DBUILD_PACKAGES="pyparameterset BBSControl BBSTools ExpIon pystationresponse pyparmdb MWImager DPPP AOFlagger LofarStMan MSLofar Pipeline" \
  cmake -DCASACORE_ROOT_DIR=/opt/casacore \
        -DPYRAP_ROOT_DIR=/opt/pyrap       \
        -DWCSLIB_ROOT_DIR=/opt/wcslib     \
        -DCASAREST_ROOT_DIR=/opt/casarest \
        -DBUILD_SHARED_LIBS=ON            \
        -DBUILD_PACKAGES="Offline"        \
        -DCMAKE_INSTALL_PREFIX=$INSTALLROOT/archive/lofim/r$LOFARVER \
        $LOFARROOT

  echo "Building."
  make -j8
  check_result "LofIm" "make" $?

  echo "Installing."
  make install
  check_result "LofIm" "make install" $?
else
  echo "Requested build already available."
fi

if [ $DEFAULT ]
then
  install_symlink $LOFARVER $INSTALL_DIRECTORY
fi

echo "Done."
