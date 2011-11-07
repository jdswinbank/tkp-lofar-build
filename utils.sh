send_mail() {
    echo "Falure when running $2." | mail -s "Build failure on heastro1: $1" jds
}

check_result() {
    COMPONENT=$1
    STEP=$2
    TARGET=$3
    RESULT=$4
    if [ $RESULT -ne 0 ]
    then
        message="$STEP failed: returned value $RESULT"
        echo $message
        send_mail $COMPONENT $message
        rm -rf $TARGET
        exit 1
    fi
}

update_source() {
    SOURCENAME=$1
    SOURCEDIR=$2
    REVISION=$3
    cd $SOURCEDIR
    echo "Updating $SOURCENAME sources."
    git clean -df
    git checkout -f master
    git svn rebase
    if [ $REVISION ]
    then
        echo "Checking out r$REVISION."
        git checkout `git svn find-rev r$REVISION`
        VERSION=$REVISION
    else
        # Take the version of the remote branch, ignoring local changes
        VERSION=`git svn find-rev git-svn`
    fi
}
