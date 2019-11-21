#!/bin/bash
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==#
# Script Name: aws-instance_start-stop.sh
# Date: Nov 20, 2019.
# Modified: NA.
# Versioning: NA.
# Author: Krishna Bagal.
# Info: Script will start stopped aws ec2 instance.
# Ticket: NA
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==#
INSTANCEPVTIP=$1
INSTANCESTATUS=$2

# To get instnace id.
INSTNACEID=$(aws ec2 describe-instances --filter "Name=private-ip-address,Values=$INSTANCEPVTIP" |grep -i "instanceid" |cut -d":" -f2 |sed -E 's/\",|\ "//g')

# To get instnace status code.
CODE=$(aws ec2 describe-instances --filter "Name=private-ip-address,Values=$INSTANCEPVTIP" |grep -w "Code" |cut -d":" -f2 |sed -E 's/\",|\ "|,//g' |tail -1)

# Instance Status Code
# 0 : pending
# 16 : running
# 32 : shutting-down
# 48 : terminated
# 64 : stopping
# 80 : stopped

if [ "$CODE" == "" ];
then
    echo "INFO: $INSTANCEPVTIP : No such Instance configured"
    exit 0
else
    if [ "$INSTANCESTATUS" == "start" ];
    then
        if [ $CODE == "16" ];
        then
            echo "WARNING: $INSTANCEPVTIP:Instance Is Already Running."
        else
            aws ec2 start-instances --instance-ids $INSTNACEID
            echo "OK:$INSTANCEPVTIP:Instance $2 Will Start In 30 Secs."
            exit 0
        fi
    elif [ "$INSTANCESTATUS" == "stop" ];
    then
        if [ $CODE == "80" ];
        then
            echo "WARNING: $INSTANCEPVTIP:Instance Is Already Stopped."
          else
            aws ec2 stop-instances --instance-ids $INSTNACEID
            echo "OK:$INSTANCEPVTIP:Instance $2 Will Stop In 30 Secs."
            exit 0
        fi
    fi
fi
