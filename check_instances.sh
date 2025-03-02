#!/bin/bash
# 
# check if the aws ec2 instances and their asscoiated tomcat processes are running in corresponding envirnonment
#    dev  - development envirnonment
#    test - test envirnonment
#    int  - integration envirnonment
#    ppe  - performance envirnonment
#    prod - production envirnonment
#

if [[ $# -gt 0 ]]; then
   if 
      [ "$1" = "dev" ] || [ "$1" = "test" ] ||
      [ "$1" = "int" ] || [ "$1" = "ppe" ]  || [ "$1" = "prod" ] ; then 
     env="$1"
   fi
fi 
if [ -z $env ]; then
   echo "$0 [dev|test|int|ppe|prod]"
   exit 1
fi

date=$(date '+%Y-%m-%d-%s')
isup=true

GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'

#retrieve ec2 instances
aws ec2 describe-instances --query 'jsondata[ ].Instances[ ].[InstanceId, [Tags[?keys='$env'].Value] [0][0]' --output table | grep 'Instances' | > /tmp/instance-output-$date

#check tomcat process
while read instance; 
do 
   ping -c1 -W1 $instance 2>&1 > /dev/null && isup=true || isup=false
   if  $isup ; then
     echo -e "${GREEN}$instance is up${NC}"	   
     ssh -o ConnectTimeout=10 -i ~/.ssh/ec2-user.key ec2-user@$instance 'ps -ledf | grep java | grep -v bash' > /tmp/tomcat-output-$date </dev/null
     num=`wc -l < /tmp/tomcat-output-$date`
     if [ $num -eq 1 ]; then
       echo -e "	${GREEN}tomcat is up${NC}"
     else
       echo -e "	${RED}tomcat is down for : $instance${NC}"
     fi
   else
     echo -e "${RED}$instance is down${NC}"	   
   fi	   
done < /tmp/instance-output-$date

rm -f /tmp/tomcat-output-$date
rm -f /tmp/instance-output-$date


