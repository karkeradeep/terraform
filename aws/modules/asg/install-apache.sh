#!/bin/bash

# Install Updates
sudo yum check-update
sudo yum -y update
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
      <script src="http://www.atmrum.net/rum.js"></script>
      <script>rum.start("658c7c82d2d479b48971218516a82493");</script>
    </BODY>
</HTML>
EOF