#Install IDS directly to the web server
#Detect SQL injection attacks, without traffic mirroring

# Lauches the EC2 IDS instance
# aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type ec2 --key-name keyPairIDS --security-group-ids sg-xxx --subnet-id subnet-xxx

# Installation Snort
# https://www.snort.org/documents#OfficialDocumentation
sudo apt install snort

# Snort IDS mode
# Possible to change config in cmd line with --lua
snort -c /etc/snort/snort.lua -r /var/www/dvwa

# Snort SQL Injection detection
# https://www.hackingarticles.in/detect-sql-injection-attack-using-snort-ids/
alert tcp any any -> any 80 (msg: "Error Based SQL Injection Detected"; content: "%27" ; sid:100000011; )
alert tcp any any -> any 80 (msg: "Error Based SQL Injection Detected"; content: "%22" ; sid:100000012; )

# https://medium.com/@johnsamuelthiongo52/sql-injection-ids-using-snort-ffd639cb0f3f
alert tcp any any -> any any (msg:”Possible SQL Injection — Inline Comments Detected”; flow:to_server,established; content:”GET”; nocase; http_method; content:”/”; http_uri; pcre:”/\?.*( — |#|\/\*)/”; sid:1000001;)
alert tcp any any -> any any (msg:”Possible Boolean-based Blind SQL Injection Attempt”; flow:to_server,established; content:”GET”; nocase; http_method; content:”/”; http_uri; pcre:”/\?.*(\bselect\b|\bunion\b|\band\b|\bor\b)(?:[^=]*=){2}[^&]*’/i”; sid:1000002;)
alert tcp any any -> any 80 (msg:”Possible SQL Injection — UNION keyword detected”; flow:to_server,established; content:”UNION”; nocase; http_uri; sid:1000003;)
alert tcp any any -> any 80 (msg:”Possible Manual Injection detected”; flow:to_server,established; content:”GET”; http_method; content:”?parameter=malicious_keyword”; http_uri; sid:1000004;)
