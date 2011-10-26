#!/bin/sh

CASARESTROOT=/var/scratch/casarest
INSTALLROOT=/opt

WCSLIBROOT=/opt/wcslib
CASACOREROOT=/opt/casacore

update="1"

. `dirname ${0}`/utils.sh

install_symlink() {
    echo "Updating default symlink."
    rm $INSTALLROOT/archive/casarest/default
    ln -s $2 $INSTALLROOT/archive/casarest/default
    echo "Using casarest r$1."
}

# -l          -- update sources
# -r <number> -- use specific revision
# -f          -- force build, even if specified version already exists
# -d          -- install this as default option
# -s          -- suffix for install directory
while getopts lr:s:fd optionName
do
    case $optionName in
        l) update="";;
        r) REVISION=$OPTARG;;
        s) SUFFIX=$OPTARG;;
        f) FORCE=1;;
        d) DEFAULT=1;;
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
INSTALL_DIRECTORY=$INSTALLROOT/archive/casarest/r$CASAREST_VER${SUFFIX:+-${SUFFIX}}

# Only build if either -f was specified or the destination doesn't exist
if [ $FORCE ] || [ ! -d $INSTALL_DIRECTORY ]
then
  echo "Configuring."
  mkdir -p $CASARESTROOT/build
  cd $CASARESTROOT/build
  cmake -DWCSLIB_ROOT_DIR=$WCSLIBROOT -DCASACORE_ROOT_DIR=$CASACOREROOT -DCMAKE_INSTALL_PREFIX=$INSTALL_DIRECTORY $CASARESTROOT

  echo "Building."
  make -j8
  check_result "casarest" "make" $?

  echo "Installing."
  make install
  check_result "casarest" "make install" $?
else
    echo "Already at the latest version."
fi

# If -d was specified, install this as the default version
if [ $DEFAULT ]
then
  install_symlink $CASAREST_VER $INSTALL_DIRECTORY
fi

echo "Done."
