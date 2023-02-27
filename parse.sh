#! /bin/bash

LOGFILE="/tmp/access.log"
REPORTFILE="/tmp/message.txt"
LASTTIMEFILE="/tmp/last_start.txt"
LOCKFILE="/tmp/lockfile"

if ( set -o noclobber; echo "$$" > "$LOCKFILE") 2> /dev/null;
then
    trap 'rm -f "$LOCKFILE"; exit $?' INT TERM EXIT
    exec 1>$REPORTFILE

    time_start=`date -d'now' +[%d/%b/%Y:%H:%M:%S`
    time_last_start=`date -d"$(cat "/tmp/last_start.txt")" "+[%d/%b/%Y:%H:%M:%S"`

    echo "time_end"
    echo $time_start

    echo "time_begin"
    echo $time_last_start
    echo ""

    exec 1>$LASTTIMEFILE
    echo `date -d'now'`

    exec 1>>$REPORTFILE
    echo "Топ 10 ip адресов:"
    echo "==================================="
    awk -vDate="$time_start" -vDate_end="$time_last_start" ' { if ($4 < Date && $4 >= Date_end) print $1}' $LOGFILE | sort | uniq -c | sort -rn | head -10
    echo ""

    echo "Топ 10 запросов:"
    echo "==================================="
    awk -vDate="$time_start" -vDate_end="$time_last_start" ' { if ($4 < Date && $4 >= Date_end) print $11}' $LOGFILE | sort | uniq -c | sort -rn | head -10
    echo ""

    echo "Все ошибки:"
    echo "==================================="
    awk -vDate="$time_start" -vDate_end="$time_last_start" ' { if ($4 < Date && $4 >= Date_end && $9 >=400 && $9<=500) print $9}' $LOGFILE | sort | uniq -c | sort -rn
    echo ""

    echo "Все коды возврата:"
    echo "==================================="
    awk -vDate="$time_start" -vDate_end="$time_last_start" ' { if ($4 < Date && $4 >= Date_end) print $9}' $LOGFILE | sort | uniq -c | sort -rn

    cat /tmp/message.txt | mailx -s "access_report" root@localhost
    rm -f "$LOCKFILE"
    trap - INT TERM EXIT
else
    echo "Failed to acquire lockfile: $LOCKFILE."
    echo "Held by $(cat $LOCKFILE)"
fi
