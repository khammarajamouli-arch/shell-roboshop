#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
START_TIME=$(date +%s)
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

dnf install mysql-server -y &>>LOG_FILE
VALIDATE $?  "installing mysql server"

systemctl enable mysqld &>>LOG_FILE
VALIDATE $? "enabling mysqld"

systemctl start mysqld  &>>LOG_FILE
VALIDATE $? "starting the mysqld"

mysql_secure_installation --set-root-pass RoboShop@1

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
eecho -e "Script executed in: $Y $TOTAL_TIME Seconds $N"