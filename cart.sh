#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
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


dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling NodeJS"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $?  "installing NodeJS"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "user already exists ... $Y SKIPPING $N"
fi


mkdir -p /app
VALIDATE $? "Creating app directory" 

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart application"

cd /app 
VALIDATE $? "Changing the app directory" 

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzip the cart"

npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies" 

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copy the systemctl  service"

systemctl daemon-reload

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enabling the cart"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "starting the cart"