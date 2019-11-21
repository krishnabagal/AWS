#!/bin/bash
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==#
# Script Name: aws-instance_start-stop.sh
# Date: Nov 20, 2019.
# Modified: Nov 21, 2019..
# Versioning: 0.1 : Search using instance tag.
# 		with -n [Instance-Name] -s [start OR stop]
# Author: Krishna Bagal.
# Info: Script will start stopped aws ec2 instance.
# Ticket: NA
#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==#
while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo " "
      echo "Use: aws-instance_start-stop.sh -n [Instance-Name] -s [start OR stop]"
      echo " "
      echo "Options:"
      echo "-h, --help               Show Brief Help."
      echo "-n, --action=ACTION      Specify The Instance Name."
      echo "-s, --status=ACTION      Specify The Status Action."
      echo " "
      exit 0
      ;;
    -n | --name)
      shift
      if test $# -ge 2; then
        export INSTANCENAME=$1
      else
        echo "WARNING: No Instance Name Specified OR -s Flag Is Missing."
        exit 1
      fi
      shift
      ;;
    -s | --status)
      shift
      if test $# -gt 0; then
        export INSTANCESTATUS=$1
      else
        echo "WARNING: No Instance Status Specified."
      	echo "Use: aws-instance_start-stop.sh -n [Instance-Name] -s [start OR stop]"
        exit 1
      fi
      shift
      ;;
    *)
      echo " "
      echo "Use: aws-instance_start-stop.sh -n [Instance-Name] -s [start OR stop]"
      echo " "
      echo "Options:"
      echo "-h, --help               Show Brief Help."
      echo "-n, --action=ACTION      Specify The Instance Name."
      echo "-s, --status=ACTION      Specify The Status Action."
      echo " "
      exit 0
      break
      ;;
  esac
done

# To get instnace id.
INSTNACEID=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=$INSTANCENAME" |grep -i "instanceid" |cut -d":" -f2 |sed -E 's/\",|\ "//g')

# To get instnace status code.
CODE=$(aws ec2 describe-instances --filter "Name=tag:Name,Values=$INSTANCENAME" |grep -w "Code" |cut -d":" -f2 |sed -E 's/\",|\ "|,//g' |tail -1)

# Instance Status Code
# 0 : pending
# 16 : running
# 32 : shutting-down
# 48 : terminated
# 64 : stopping
# 80 : stopped

if [ "$CODE" == "" ];
then
    echo "INFO: $INSTANCENAME : No such Instance configured"
    exit 0
else
    if [ "$INSTANCESTATUS" == "start" ];
    then
        if [ $CODE == "16" ];
        then
            echo "WARNING: $INSTANCENAME:Instance Is Already Running."
        else
            aws ec2 start-instances --instance-ids $INSTNACEID > /dev/null 2>&1
            echo "OK:$INSTANCENAME:Instance $2 Will Start In 30 Secs."
            exit 0
        fi
    elif [ "$INSTANCESTATUS" == "stop" ];
    then
        if [ $CODE == "80" ];
        then
            echo "WARNING: $INSTANCENAME:Instance Is Already Stopped."
          else
            aws ec2 stop-instances --instance-ids $INSTNACEID > /dev/null 2>&1
            echo "OK:$INSTANCENAME:Instance $2 Will Stop In 30 Secs."
            exit 0
        fi
    fi
fi
