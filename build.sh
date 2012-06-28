#!/bin/sh

set -e

# User & host for heastro1. Required for cloning repositories.
HEASTRO1=jds@heastro1.science.uva.nl

# Location of sources
SOURCE=/home/jds/src

# Target directory for installation
TARGET=/home/jds/sw
echo "Installing into $TARGET."
CASACORE_TARGET=$TARGET  #/casacore
CASAREST_TARGET=$TARGET  #/casarest
LOFAR_TARGET=$TARGET     #/LofIm
PELICAN_TARGET=$TARGET   #/pelican

# Locations of casacore measures data
DATADIR=$TARGET/share/measures/data

# LOFARSOFT packages to be built
LOFARPACKAGES=LofarStMan

# Number of simultaneous jobs
BUILD_JOBS=4

# Base directory for local patches
PATCHES=$(cd $(dirname "$0"); pwd)

mkdir -p $SOURCE

echo "Fetching measures data"
mkdir -p `dirname $DATADIR`
wget -O- ftp://ftp.atnf.csiro.au/pub/software/measures_data/measures_data.tar.bz2 | tar jxvC `dirname $DATADIR`

# Update & build casacore
echo "Fetching casacore."
cd $SOURCE
if [ ! -d casacore ]; then
    git clone ${HEASTRO1}:/var/scratch/casacore ./casacore
fi
cd casacore
git checkout -f master
git clean -dfx
echo "Configuring casacore."
mkdir -p $SOURCE/casacore/build/opt
cd $SOURCE/casacore/build/opt
cmake -DCMAKE_INSTALL_PREFIX=$CASACORE_TARGET \
    -DUSE_HDF5=OFF                            \
    -DDATA_DIR=$DATADIR                       \
    $SOURCE/casacore
echo "Building casacore."
make -j${BUILD_JOBS}
echo "Installing casacore."
make install
echo "Built & installed casacore"

echo "Fetching casarest."
cd $SOURCE
if [ ! -d casarest ]; then
    git clone ${HEASTRO1}:/var/scratch/casarest ./casarest
fi
cd casarest
git checkout -f master
git clean -dfx
echo "Configuring casarest"
mkdir -p $SOURCE/casarest/build
cd $SOURCE/casarest/build
cmake -DCASACORE_ROOT_DIR=$CASACORE_TARGET    \
    -DCMAKE_INSTALL_PREFIX=$CASAREST_TARGET \
    $SOURCE/casarest
echo "Building casarest."
make -j${BUILD_JOBS}
echo "Installing casarest."
make install
echo "Built & installed casarest"

echo "Fetching LofIm."
cd $SOURCE
if [ ! -d LOFAR ]; then
    git clone ${HEASTRO1}:/var/scratch/LOFAR ./LOFAR
fi
cd LOFAR
git checkout -f master
git clean -dfx
echo "Applying local patches to LofIm."
for patchfile in $PATCHES/lofar-patches/*patch
do
    echo $patchfile
    git apply $patchfile
done

echo "Configuring LofIm."
# First update the list of available LOFAR packages
$SOURCE/LOFAR/CMake/gen_LofarPackageList_cmake.sh
mkdir -p $SOURCE/LOFAR/build/gnu_opt
cd $SOURCE/LOFAR/build/gnu_opt
cmake -DCASACORE_ROOT_DIR=$CASACORE_TARGET \
    -DCASAREST_ROOT_DIR=$CASAREST_TARGET   \
    -DBUILD_SHARED_LIBS=ON                 \
    -DBUILD_PACKAGES=$LOFARPACKAGES        \
    -DCMAKE_INSTALL_PREFIX=$LOFAR_TARGET   \
    $SOURCE/LOFAR
echo "Building LofIm."
make -j${BUILD_JOBS}
echo "Installing LofIm."
make install
echo "Built & installed LofIm."

echo "Fetching Pelican"
cd $SOURCE
if [ ! -d pelican ]; then
    git clone https://github.com/pelican/pelican.git
fi
cd pelican
git checkout -f master
git clean -dfx
echo "Configuring Pelican"
mkdir -p pelican/build
cd pelican/build
cmake                                                     \
    -DCMAKE_BUILD_TYPE=release                            \
    -DCMAKE_INSTALL_PREFIX=$PELICAN_TARGET                \
    ../CMakeLists.txt
echo "Building pelican"
cd ..
make -j${BUILD_JOBS}
echo "Installing pelican"
make install

echo "Done."
