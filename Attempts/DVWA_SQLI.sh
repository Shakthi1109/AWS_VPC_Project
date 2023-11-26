#curl https://github.com/digininja/DVWA/archive/master.zip
git clone https://github.com/digininja/DVWA

chmod -R 777 DVWA/

cd DVWA/config

sudo cp config.inc.php.dist config.inc.php

#http://10.0.1.0/dvwa/vulnerabilities/sqli/?id='%'&Submit=Submit#
