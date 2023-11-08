#!/bin/sh

# Updating packages
sudo yum update -y

# Installing apache server
sudo yum install -y httpd

# Creating an index.html file for apache main page
{
echo "<!DOCTYPE html>"
echo "<html>"
echo "<body>"
echo "<h1>Bonjour tout le monde!</h1>"
echo "<p>Welcome to my page.</p>"
echo "</body>"
echo "</html>"
}>> index.html

sudo mv index.html /var/www/html/index.html
# Giving permissions to the file so Apache can have access to it
sudo chmod 777 /var/www/html/index.html

# Running the server
sudo service httpd start
