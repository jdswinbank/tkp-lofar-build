send_mail() {
    echo "Falure when running $2." | mail -s "Build failure on heastro1: $1" jds
}

check_result() {
    if [ $3 -ne 0 ]
    then
        message="$2 failed: returned value $3"
        echo $message
        send_mail $1 $message
        exit 1
    fi
}

update_source() {
    SOURCENAME=$1
    SOURCEDIR=$2
    REVISION=$3
    cd $SOURCEDIR
    echo "Updating $SOURCENAME sources."
    git stash
    git clean -df
    git svn rebase
    if [ $REVISION ]
    then
        echo "Checking out r$REVISION."
        git checkout `git svn find-rev r$REVISION`
    fi
    git stash pop
    VERSION=`git svn find-rev HEAD`
}