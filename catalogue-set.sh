#!/bin/bash

#this script to use set and trap commands instead of using validate command throughout the script.
#Note here in this script i am erasing all validate commands to know the use of set and trap commands and intentionally created an error in line no.

set -euo pipefail

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.rajamouli.online

mkdir -p $LOGS_FOLDER

echo "Script started at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privilage"
    exit 1
fi


dnf module disable nodejs -y &>>LOG_FILE

dnf module enable nodejs:20 -y &>>LOG_FILE

dnf install nodejs -y &>>LOG_FILE

id roboshop &>>LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOG_FILE
else
    echo -e "user already exists ... $Y SKIPPING $N"
fi


mkdir -p /app

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_FILE

cd /app 

rm -rf /app/*

unzip /tmp/catalogue.zip &>>LOG_FILE

npm install &>>LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service 

systemctl daemon-reload

systemctl enable cataloguee &>>LOG_FILE

systemctl start catalogue &>>LOG_FILE

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>LOG_FILE

INDEX=$(mongosh mongodb.rajamouli.online --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
   mongosh --host $MONGODB_HOST </app/db/master-data.js &>>LOG_FILE
else
   echo -e "catalouge products already loaded... $Y SKIPPING $N"
fi

systemctl restart catalogue &>>LOG_FILE