#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER

echo "Script started at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privilage"
    exit 1
fi


VALIDATE(){
    if [ $1 -ne 0 ]; then
         echo -e "$2 ... $R is failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo  -e "$2 .... $G is success $N" | tee -a $LOG_FILE
    fi

}

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "disabling redis"
dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $?  "enabling redis"
dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/  c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connections to redis"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "enabling the redis"
systemctl start redis &>>$LOG_FILE
VALIDATE $? "starting the redis"