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
MYSQL_HOST=mysql.rajamouli.online

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


dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing the maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating system user"
else
    echo -e "user already exists ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory" 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping application"

cd /app 
VALIDATE $? "Changing the app directory" 

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip the shipping"

cd /app 
mvn clean package &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload
systemctl enable shipping &>>$LOG_FILE

dnf install mysql -y &>>$LOG_FILE

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
       mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
       mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
       mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
       echo -e "Shipping data is already loaded ... $Y SKIPPING $N"

fi   
   
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting the shipping service"