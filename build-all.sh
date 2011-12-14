#!/bin/sh

# Target directory for installation
TARGET=/opt/archive/`date +%F-%H-%M`
echo "Installing into $TARGET."
CASACORE_TARGET=$TARGET/casacore
CASAREST_TARGET=$TARGET/casarest
PYRAP_TARGET=$TARGET/pyrap
PYRAP_PYTHON_TARGET=$PYRAP_TARGET/lib/python2.6/dist-packages
LOFAR_TARGET=$TARGET/LofIm

# Locations of checked-out source
CASACOREROOT=/var/scratch/casacore
CASARESTROOT=/var/scratch/casarest
PYRAPROOT=/var/scratch/pyrap
LOFARROOT=/var/scratch/LOFAR

# Base directory for local patches
PATCHES=$(cd $(dirname "$0"); pwd)

# LOFARSOFT packages to be built
LOFARPACKAGES=Offline\;LofarFT\;Deployment\;SPW_Combine
#LOFARPACKAGES="pyparameterset BBSControl BBSTools ExpIon pystationresponse pyparmdb MWImager DPPP AOFlagger LofarStMan MSLofar Pipeline"

# Locations of dependencies
WCSLIBROOT=/opt/archive/wcslib/4.8.2
DATADIR=/opt/measures/data

# Pull in some utility functions
. `dirname ${0}`/utils.sh

# Optional command line arguments to specify revision to build.
while getopts l:c:r:p: optionName
do
    case $optionName in
        l) LOFAR_REVISION=$OPTARG;;
        c) CASACORE_REVISION=$OPTARG;;
        r) CASAREST_REVISION=$OPTARG;;
        p) PYRAP_REVISION=$OPTARG;;
        \?) exit 1;;
    esac
done

# Update & build casacore
update_source "casacore" $CASACOREROOT $CASACORE_REVISION
CASACORE_VERSION=$VERSION
echo "Configuring casacore r$CASACORE_VERSION."
mkdir -p $CASACOREROOT/build/opt
cd $CASACOREROOT/build/opt
cmake -DCMAKE_INSTALL_PREFIX=$CASACORE_TARGET \
    -DUSE_HDF5=OFF                            \
    -DWCSLIB_ROOT_DIR=$WCSLIBROOT             \
    -DDATA_DIR=$DATADIR $CASACOREROOT
echo "Building casacore."
make -j8
check_result "casacore" "make" $TARGET $?
echo "Installing casacore."
make install
check_result "casacore" "make install" $TARGET $?
echo "Built & installed casacore r$CASACORE_VERSION."

# Update & build casarest
update_source "casarest" $CASARESTROOT $CASAREST_REVISION
CASAREST_VERSION=$VERSION
echo "Configuring casarest r$CASAREST_VERSION."
mkdir -p $CASARESTROOT/build
cd $CASARESTROOT/build
cmake -DWCSLIB_ROOT_DIR=$WCSLIBROOT         \
    -DCASACORE_ROOT_DIR=$CASACORE_TARGET    \
    -DCMAKE_INSTALL_PREFIX=$CASAREST_TARGET \
    $CASARESTROOT
echo "Building casarest."
make -j8
check_result "casarest" "make" $TARGET $?
echo "Installing casarest."
make install
check_result "casarest" "make install" $TARGET $?
echo "Built & installed casarest r$CASAREST_VERSION."

# Update & build pyrap
update_source "pyrap" $PYRAPROOT $PYRAP_REVISION
PYRAP_VERSION=$VERSION
echo "Building & installing pyrap r$PYRAP_VERSION."
mkdir -p $PYRAP_PYTHON_TARGET
cd $PYRAPROOT
./batchbuild-trunk.py --casacore-root=$CASACORE_TARGET \
    --wcs-root=$WCSLIBROOT \
    --prefix=$PYRAP_TARGET \
    --python-prefix=$PYRAP_PYTHON_TARGET
check_result "pyrap" "batchbuild-trunk" $TARGET $?
echo "Built & installed pyrap r$PYRAP_VERSION."

# Update LofIm, insert ASKAP dependencies, and build
update_source "LofIm" $LOFARROOT $LOFAR_REVISION
LOFAR_VERSION=$VERSION

echo "Inserting external ASKAPsoft dependencies."
CLUSTERBUILD=`date --date="today" +%a`
for path in Base/accessors/src \
    Base/askap/src \
    Base/mwcommon/src \
    Base/scimath/src \
    Components/Synthesis/synthesis/src
do
  rsync -tvvr --exclude=.svn \
  lhn001:/opt/cep/LofIm/daily/$CLUSTERBUILD/lofar_build/LOFAR/CEP/Imager/ASKAPsoft/$path/ \
  $LOFARROOT/CEP/Imager/ASKAPsoft/$path
done

echo "Applying local patches."
for patchfile in $PATCHES/lofar-patches/*patch
do
    echo $patchfile
    git apply $patchfile
    check_result "LofIm" "git apply $patchfile" $TARGET $?
done

echo "Configuring LofIm r$LOFAR_VERSION."
# First update the list of available LOFAR packages
$LOFARROOT/CMake/gen_LofarPackageList_cmake.sh
mkdir -p $LOFARROOT/build/gnu_opt
cd $LOFARROOT/build/gnu_opt
cmake -DCASACORE_ROOT_DIR=$CASACORE_TARGET \
    -DPYRAP_ROOT_DIR=$PYRAP_TARGET         \
    -DWCSLIB_ROOT_DIR=$WCSLIBROOT          \
    -DCASAREST_ROOT_DIR=$CASAREST_TARGET   \
    -DBUILD_SHARED_LIBS=ON                 \
    -DBUILD_PACKAGES=$LOFARPACKAGES        \
    -DCMAKE_INSTALL_PREFIX=$LOFAR_TARGET   \
    -DUSE_LOG4CPLUS=OFF                    \
    $LOFARROOT
echo "Building LofIm."
make -j8
check_result "LofIm" "make" $TARGET $?
echo "Installing LofIm."
make install
check_result "LofIm" "make install" $TARGET $?
echo "Built & installed LofIm r$LOFAR_VERSION."

echo "Copying cookbook tools to local host."
rsync -r lhn001:/opt/cep/tools/cookbook $TARGET
check_result "Cookbook tools" "rsync" $TARGET $?

echo "Generating init.sh."
INITFILE=$TARGET/init.sh
cat > $INITFILE <<-END
# wcslib
export LD_LIBRARY_PATH=$WCSLIBROOT/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
export PATH=$WCSLIBROOT/bin\${PATH:+:\${PATH}}

# casacore
export LD_LIBRARY_PATH=$CASACORE_TARGET/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
export PATH=$CASACORE_TARGET/bin\${PATH:+:\${PATH}}

# casarest
export LD_LIBRARY_PATH=$CASAREST_TARGET/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
export PATH=$CASAREST_TARGET/bin\${PATH:+:\${PATH}}

# pyrap
export LD_LIBRARY_PATH=$PYRAP_TARGET/lib\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}
export PYTHONPATH=$PYRAP_PYTHON_TARGET\${PYTHONPATH:+:\${PYTHONPATH}}

# cookbook tools
export PATH=$TARGET/cookbook\${PATH:+:\${PATH}}

# LofIm
. $LOFAR_TARGET/lofarinit.sh
END

# Install this build as the default
rm /opt/archive/init.sh
ln -s $INITFILE /opt/archive/init.sh

# Install symlinks for backwards compatibility
rm /opt/archive/casacore/default
ln -s $CASACORE_TARGET /opt/archive/casacore/default
rm /opt/archive/casarest/default
ln -s $CASAREST_TARGET /opt/archive/casarest/default
rm /opt/archive/pyrap/default
ln -s $PYRAP_TARGET /opt/archive/pyrap/default
rm /opt/archive/lofim/default
ln -s $LOFAR_TARGET /opt/archive/lofim/default

echo "Done."
