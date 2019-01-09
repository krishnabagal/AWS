#!/bin/bash
#================================================#
#Script Name: Instance_Start-Stop.sh
#Date: May 22, 2017.
#Owner: Krishna Bagal.
#Info: to start,stop AWS instance.
#================================================#
export AWS_ACCESS_KEY=<KEY>
export AWS_SECRET_KEY=<KEY>

if [ "$1" == "-status" ];then
  instance_id=$(ec2-describe-instances --filter "private-ip-address=$2"|tail -n1|awk '{print $3}')
	  if [ "$instance_id" == "" ];then
		    echo "No such Instance configured";
	  else
	      state=$(ec2-describe-instance-status $instance_id |tail -n1|awk '{print $3}')
                if [ "$state" == "" ]; then
                        echo "Instance $2 Instance-ID $instance_id is Down"
                else
                        echo "Instance $2 Instance-ID $instance_id is $state"

                fi
	  fi

elif [ "$1" == "-start" ];then

	instance_id=$(ec2-describe-instances --filter "private-ip-address=$2"|tail -n1|awk '{print $3}')

	  if [ "$instance_id" == "" ];then
		    echo "No such Instance configured";
	  else
		    ec2-start-instances $instance_id
		    echo "Instance $2 will start in 30 secs";
	  fi

elif [ "$1" == "-stop" ];then

	instance_id=$(ec2-describe-instances --filter "private-ip-address=$2"|tail -n1|awk '{print $3}')

	if [ "$instance_id" == "" ];then
		echo "No such Instance configured";
	else
		ec2-stop-instances $instance_id
		echo "Instance $2 is shutting down";
	fi

elif [ "$1" == "" ]|| [ "$1" == "--help" ] ||[ "$1" == "-help" ] || [ "$1" == "-h" ] || [ "$1" == "help" ] || [ "$1" == "" ] ;then

	echo "Usage:
	-status <ip-address>
	-start  <ip-address>
	-stop   <ip-address>
	"
fi
