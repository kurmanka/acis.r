#!/bin/bash
# http://stackoverflow.com/questions/525247/how-do-i-daemonize-an-arbitrary-script-in-unix

if [[ $# < 1 ]]; then
    echo "Name of pid file not given."
    exit
fi

# Get the pid file's name.
PIDFILE=$1
shift

if [[ $# < 1 ]]; then
    echo "No command given."
    exit
fi

echo "Checking pid in file $PIDFILE."

#Check to see if process running.
PID=$(cat $PIDFILE 2>/dev/null)
if [[ $? = 0 ]]; then
    ps -p $PID >/dev/null 2>&1
    if [[ $? = 0 ]]; then
        echo "Command $1 already running."
        exit
    fi
fi

# Write our pid to file.
echo $$ >$PIDFILE

# Get command.
COMMAND=$1
shift

# Run command until we're killed.
while true; do
    $COMMAND "$*"
    sleep 10 # if command dies immediately, don't go into un-ctrl-c-able loop
done
