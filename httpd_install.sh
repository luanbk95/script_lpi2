#!/bin/bash


systemctl status httpd 2>check_error.txt 1>check_status.txt
if grep -Fxq "Unit httpd.service could not be found." check_error.txt
then
	yum install -y httpd
	systemctl start httpd.service
	systemctl enable httpd.service
	netstat -nltpu | grep 80
	sleep 5

	echo "Tao thu muc cho website cua ban: /var/www/html/myweb"
	mkdir /var/www/html/myweb
	sleep 3
	echo "Tao file index.html trong thu muc tren..."
	echo -n "Hay nhap dong chu welcome - noi dung file index.html: "
	read welcome
	echo -e "<html>\n\t<head><title>TestPage</title></head>\n\t\t<body>\n\t\t\t<p> $welcome </p>\n\t\t</body>\n</html>" > /var/www/html/myweb/index.html
	echo "Đã tạo file index.html"
	sleep 3

	if [ ! -e /etc/httpd/conf/httpd_backup.conf ]
	then
		echo "Backup file config cua httpd..."
		cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd_backup.conf
		echo "Done. /etc/httpd/conf/httpd_backup.conf"
	fi

	sed -i 's/\/var\/www\/html/\/var\/www\/html\/myweb/' /etc/httpd/conf/httpd.conf

	echo "Da chinh sua file config httpd"
	echo "Restart httpd..."
	systemctl restart httpd

	ip_linux=`ip a | grep ens33 | sed -n 2p | cut -f 6 -d' ' | cut -f1 -d'/'`
	echo "Use browser for http://$ip_linux"

	while [ "$check_via_browser" != "done" ]
	do
		echo "Type \"done\" if you've done: "
		read check_via_browser
	done
fi

if grep -q "Active: inactive (dead)" check_status.txt
then
	systemctl start httpd
fi

# Tao virtual host
########################################
while true
do
        echo -n "Ban co muon tao mot virtual host cho webserver khong? (y/n): "
        read tao_virutal
        if [ "$tao_virutal" = "y" ]
        then
                echo -n "Nhap ten virtual host ma ban muon (only 1 word): "
                read virtual_name

                ip_virtual=`shuf -i 10-255 -n 1`
                ifconfig ens33:$ip_virtual 192.168.200.$ip_virtual netmask 255.255.255.0 up

                cp /etc/sysconfig/network-scripts/ifcfg-ens33 /etc/sysconfig/network-scripts/ifcfg-ens33:$ip_virtual
                echo -e "TYPE="Ethernet"\nPROXY_METHOD="none"\nBROWSER_ONLY="no"\nBOOTPROTO="static"\nDEFROUTE="yes"\nIPV4_FAILURE_FATAL="no"\nNAME="ens33:$ip_virtual"\nDEVICE="ens33:$ip_virtual"\nONBOOT="yes"\nIPADDR=192.168.200.${ip_virtual}\nNETMASK=255.255.255.0\nGATEWAY=192.168.200.2\nDNS1=8.8.8.8" > /etc/sysconfig/network-scripts/ifcfg-ens33:$ip_virtual
                systemctl restart network

                echo -e "\nNameVirtualHost 192.168.200.${ip_virtual}:80\n<VirtualHost 192.168.200.${ip_virtual}:80>\nServerName example.com\nServerAdmin admin@example.com\nDocumentRoot /var/www/html/$virtual_name\nErrorLog /var/log/httpd/error.log\nCustomLog /var/log/httpd/access.log combined\n</VirtualHost>" >> /etc/httpd/conf/httpd.conf
                mkdir /var/www/html/$virtual_name
                echo -e "<html>\n\t<head><title>TestPage</title></head>\n\t\t<body>\n\t\t\t<p> welcome with $virtual_name </p>\n\t\t</body>\n</html>" > /var/www/html/$virtual_name/index.html
                systemctl restart httpd

                echo "Done, please check your web site at http://192.168.200.$ip_virtual"
                break
        elif [ "$tao_virutal" = "n" ]
        then
                echo "Goodbye!"
                break
        else
                echo "Hay nhap y or n"
        fi
done