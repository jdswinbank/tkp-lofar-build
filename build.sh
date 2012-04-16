#!/bin/sh

set -e

# User & host for heastro1. Required for cloning repositories.
HEASTRO1=jds@heastro1.science.uva.nl

# Location of sources
SOURCE=/var/scratch/swinbank/src

# Target directory for installation
TARGET=/var/scratch/swinbank/sw
echo "Installing into $TARGET."
WCSLIB_TARGET=$TARGET    #/wcslib
CFITSIO_TARGET=$TARGET   #/cfitsio
CASACORE_TARGET=$TARGET  #/casacore
CASAREST_TARGET=$TARGET  #/casarest
LOFAR_TARGET=$TARGET     #/LofIm
QT_TARGET=$TARGET        #/qt
CPPUNIT_TARGET=$TARGET   #/cppunit
PELICAN_TARGET=$TARGET   #/pelican

# Locations of casacore measures data
DATADIR=$TARGET/share/measures/data

# LOFARSOFT packages to be built
LOFARPACKAGES=LofarStMan

# Number of simultaneous jobs
BUILD_JOBS=16

# Base directory for local patches
PATCHES=$(cd $(dirname "$0"); pwd)

mkdir -p $SOURCE

# Download & build wcslib
echo "Fetching wcslib"
cd $SOURCE
rm -rf wcslib-4.13.4
if [ ! -f wcslib-4.13.4.tar.bz2 ]; then
    wget ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-4.13.4.tar.bz2
fi
tar jxvf wcslib-4.13.4.tar.bz2
echo "Configuring wcslib"
cd wcslib-4.13.4
mkdir -p $WCSLIB_TARGET
./configure --prefix=$WCSLIB_TARGET
echo "Building wcslib"
make -j${BUILD_JOBS}
echo "Installing wcslib"
make install

# Download & build cfitsio
echo "Fetching cfitsio"
cd $SOURCE
rm -rf cfitsio
if [ ! -f cfitsio3290.tar.gz ]; then
    wget ftp://heasarc.gsfc.nasa.gov/software/fitsio/c/cfitsio3290.tar.gz
fi
tar zxvf cfitsio3290.tar.gz
echo "Configuring cfitsio"
cd cfitsio
mkdir -p $CFITSIO_TARGET
./configure --prefix=$CFITSIO_TARGET
echo "Building cfitsio"
make -j${BUILD_JOBS} shared
echo "Installing cfitsio"
make install

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
    -DWCSLIB_ROOT_DIR=$WCSLIB_TARGET          \
    -DCFITSIO_ROOT_DOR=$CFITSIO_TARGET        \
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
cmake -DWCSLIB_ROOT_DIR=$WCSLIB_TARGET      \
    -DCASACORE_ROOT_DIR=$CASACORE_TARGET    \
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
    -DWCSLIB_ROOT_DIR=$WCSLIB_TARGET       \
    -DCASAREST_ROOT_DIR=$CASAREST_TARGET   \
    -DBUILD_SHARED_LIBS=ON                 \
    -DBUILD_PACKAGES=$LOFARPACKAGES        \
    -DCMAKE_INSTALL_PREFIX=$LOFAR_TARGET   \
    -DUSE_LOG4CPLUS=OFF                    \
    $SOURCE/LOFAR
echo "Building LofIm."
make -j${BUILD_JOBS}
echo "Installing LofIm."
make install
echo "Built & installed LofIm."

echo "Fetching Qt"
cd $SOURCE
rm -rf qt-everywhere-opensource-src-4.8.1
if [ ! -f qt-everywhere-opensource-src-4.8.1.tar.gz ]; then
    wget http://download.qt.nokia.com/qt/source/qt-everywhere-opensource-src-4.8.1.tar.gz
fi
tar zxvf qt-everywhere-opensource-src-4.8.1.tar.gz
echo "Configuring Qt"
cd qt-everywhere-opensource-src-4.8.1
mkdir -p $QT_TARGET
echo "yes" | ./configure -opensource -prefix $QT_TARGET
echo "Building Qt"
make -j${BUILD_JOBS}
echo "Installing Qt"
make install

echo "Fetching CppUnit"
cd $SOURCE
rm -rf cppunit-1.12.1
if [ ! -f cppunit-1.12.1.tar.gz ]; then
    wget http://downloads.sourceforge.net/cppunit/cppunit-1.12.1.tar.gz
fi
tar zxvf cppunit-1.12.1.tar.gz
cd cppunit-1.12.1
echo "Configuring CppUnit"
./configure --prefix=$CPPUNIT_TARGET
echo "Building CppUnit"
make -j${BUILD_JOBS}
echo "Installing CppUnit"
make install

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
PATH=$QT_TARGET/bin${PATH:+:$PATH}} cmake                 \
    -DCMAKE_BUILD_TYPE=release                            \
    -DCMAKE_INSTALL_PREFIX=$PELICAN_TARGET                \
    -DCPPUNIT_INCLUDE_DIR=$CPPUNIT_TARGET/include/cppunit \
    -DCPPUNIT_LIBRARIES=$CPPUNIT_TARGET/lib/libcppunit.so \
    ../CMakeLists.txt
echo "Building pelican"
cd ..
make -j${BUILD_JOBS}
echo "Installing pelican"
make install

echo "Done."
