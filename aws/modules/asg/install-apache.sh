#!/bin/bash

# Install Updates
sudo yum check-update
sudo yum -y update
# Install stress utility
sudo amazon-linux-extras install epel -y
sudo yum install stress -y
# Apache installation, enabling and status check
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl status httpd | grep Active

sudo cat > /var/www/html/index.html << EOF
<HTML>
    <HEAD>
        <TITLE>AWS AUTOSCALING DEMO</TITLE>
        <STYLE type="text/css">
         H1 { text-align: center}
        </STYLE>
    </HEAD>
    <BODY>
      <H1> AWS AUTOSCALING DEMO BY DEEPAK KARKERA </H1>
    </BODY>
</HTML>
EOF