#!/bin/bash
# Author: Nirjas Jakilim
# Usage: statusCheck.sh <pass the host url here>
# Description: It will check Humio and other servers status depended to it and will report it if they are down. 

flag=0 #Intial flag status
host=$1
mail_address=<put_your_mail_address_here>

if [[ -f humio.status ]]
then
rm -rf humio.status
fi

execTime() {
echo "Script executed at (BD time) : $(TZ="Asia/Dhaka" date "+%A, %d %b - %r")" >> humio.status
echo "Script executed at (UK time) : $(TZ="Europe/London" date "+%A, %d %b - %r")" >> humio.status
echo "Script executed at (NY time) : $(TZ="US/Eastern" date "+%A, %d %b - %r")" >> humio.status
echo " " >> humio.status
}

# Will output Zookeeper Status
zookeepStatus()
{
status=$(echo ruok | nc $host 2181 2> /dev/null)
if [[ $status == "imok" ]]
then
echo "Zookeeper is OK"
else
echo "Zookeeper is Not Running" >> humio.status
flag=1
fi
}

# Will output Kafka Status whether it is running or not
kafkaStatus(){
nc -z $host 9092
status=$? # Storing the return value of the previously executed command. It will be 0 if the command was successful.
if [[ $status == 0 ]]
then
echo "Kafka is OK"
else
echo "Kafka is not running" >> humio.status
flag=1
fi
}

# Will output Humio Status whether it is running or not
humioStatus()
{
status=$(curl -ks http://${host}:8080/api/v1/status | grep -o '"status": *"[^"]*' | grep -o '[^"]*$')
if [[ $status != "OK" && $status != "WARN" ]]
then
echo "Humio is not Running" >> humio.status
flag=1
elif [[ $status == "WARN" ]]
then
echo "Humio status is WARN" >> humio.status
flag=1
else
echo "Humio is $status"
fi
}

execTime
zookeepStatus
kafkaStatus
humioStatus

if [[ $flag == 1 ]]
then
mail -s "Humio Service Down Alert" -S replyto="${mail_address}" ${mail_address} < humio.status
fi

