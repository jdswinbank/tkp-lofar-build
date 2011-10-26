#!/bin/sh

CASACOREROOT=/var/scratch/casacore
INSTALLROOT=/opt

WCSLIBROOT=/opt/wcslib
DATADIR=/opt/measures/data

UPDATE="1"

. `dirname ${0}`/utils.sh

install_symlink() {
    echo "Updating default symlink."
    rm $INSTALLROOT/archive/casacore/default
    ln -s $2 $INSTALLROOT/archive/casacore/default
    echo "Using casacore r$1."
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

# Update source
cd $CASACOREROOT
if [ $UPDATE ]
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
INSTALL_DIRECTORY=$INSTALLROOT/archive/casacore/r$CASACORE_VER${SUFFIX:+-${SUFFIX}}

# Only build if either -f was specified or the destination doesn't exist
if [ $FORCE ] || [ ! -d $INSTALL_DIRECTORY ]
then
  echo "Configuring."
  mkdir -p $CASACOREROOT/build/opt
  cd $CASACOREROOT/build/opt
  cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_DIRECTORY -DUSE_HDF5=OFF -DWCSLIB_ROOT_DIR=$WCSLIBROOT -DDATA_DIR=$DATADIR ../..

  echo "Building."
  make -j8
  check_result "casacore" "make" $?

  echo "Installing."
  make install
  check_result "casacore" "make install" $?
else
  echo "Requested build already available."
fi

echo "Defaults is $DEFAULT"

# If -d was specified, install this as the default version
if [ $DEFAULT ]
then
  install_symlink $CASACORE_VER $INSTALL_DIRECTORY
fi

echo "Done."
