#!/bin/sh

BUILDROOT=/var/scratch
LOFARROOT=$BUILDROOT/LOFAR
PIPELINEROOT=$LOFARROOT/CEP/Pipeline/
INSTALLROOT=/opt/pipeline

update_lofar="1"

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

echo "Building."
cd $PIPELINEROOT/framework
python setup.py install --prefix=$INSTALLROOT/framework-`date +%Y-%m-%d` 
result=$?
if [ $result -ne 0 ]
then
    echo "Build failed! (Returned value $result)"
    exit 1
fi

echo "Updating default framework symlink."
rm $INSTALLROOT/framework
ln -s $INSTALLROOT/framework-`date +%Y-%m-%d` $INSTALLROOT/framework

echo "Copying recipes."
cp -r $PIPELINEROOT/recipes/sip $INSTALLROOT/recipes-`date +%Y-%m-%d`

echo "Updating default recipes symlink."
rm $INSTALLROOT/recipes
ln -s $INSTALLROOT/recipes-`date +%Y-%m-%d` $INSTALLROOT/recipes

echo "Using LOFARsoft r$LOFARVER."
echo "Done."
