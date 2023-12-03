#!/bin/bash


# Updating packages
sudo apt update -y
sudo apt upgrade -y

# Installing apache server
sudo apt install apache2 -y

# Creating an index.html file for apache main page
cat <<EOF > index.html
<!DOCTYPE html>
<html>
<body>
<h1>Bonjour tout le monde!</h1>
<p>Welcome to my page.</p>
</body>
</html>
EOF

sudo mv index.html /var/www/html/index.html
# Giving permissions to the file so Apache can have access to it
sudo chmod 777 /var/www/html/index.html

# Running the server
sudo systemctl start apache2

# Installation Snort
# https://www.snort.org/documents#OfficialDocumentation
sudo apt install snort -y

# Snort SQL Injection detection
# https://www.hackingarticles.in/detect-sql-injection-attack-using-snort-ids/
echo 'alert tcp any any -> any 80 (msg:"SQL Injection: %22 character"; content:"%22"; sid:1000001;)' | sudo tee -a /etc/snort/rules/local.rules # %22 -> "
echo 'alert tcp any any -> any 80 (msg:"SQL Injection: %23 character"; content:"%23"; sid:1000002;)' | sudo tee -a /etc/snort/rules/local.rules # %23 -> # 
echo 'alert tcp any any -> any 80 (msg:"SQL Injection: %27 character"; content:"%27"; sid:1000003;)' | sudo tee -a /etc/snort/rules/local.rules # %27 -> '  
echo 'alert tcp any any -> any 80 (msg:"SQL Injection: %2d character"; content:"%2d"; sid:1000004;)' | sudo tee -a /etc/snort/rules/local.rules # %2d -> -

sudo service snort restart