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
