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
alert tcp any any -> any 80 (msg: "Error Based SQL Injection Detected"; content: "%27" ; sid:100000011; )
alert tcp any any -> any 80 (msg: "Error Based SQL Injection Detected"; content: "%22" ; sid:100000012; )

# https://medium.com/@johnsamuelthiongo52/sql-injection-ids-using-snort-ffd639cb0f3f
alert tcp any any -> any any (msg:”Possible SQL Injection — Inline Comments Detected”; flow:to_server,established; content:”GET”; nocase; http_method; content:”/”; http_uri; pcre:”/\?.*( — |#|\/\*)/”; sid:1000001;)
alert tcp any any -> any any (msg:”Possible Boolean-based Blind SQL Injection Attempt”; flow:to_server,established; content:”GET”; nocase; http_method; content:”/”; http_uri; pcre:”/\?.*(\bselect\b|\bunion\b|\band\b|\bor\b)(?:[^=]*=){2}[^&]*’/i”; sid:1000002;)
alert tcp any any -> any 80 (msg:”Possible SQL Injection — UNION keyword detected”; flow:to_server,established; content:”UNION”; nocase; http_uri; sid:1000003;)
alert tcp any any -> any 80 (msg:”Possible Manual Injection detected”; flow:to_server,established; content:”GET”; http_method; content:”?parameter=malicious_keyword”; http_uri; sid:1000004;)

sudo service snort restart