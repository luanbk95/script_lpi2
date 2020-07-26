#/bin/bash

#extract ip of system
system_ip=`ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'`


forward_file () {
cat <<EOT > /var/named/${your_domain}.db
\$TTL 1D
@       IN SOA  ns1.${your_domain}. root.${your_domain}. (
                                        1       ; serial
                                       	1D      ; refresh
                                       	1H      ; retry
                                       	1W      ; expire
                                       	3H )    ; minimum
       	IN      NS      ns1.${your_domain}.
       	IN      MX      10 mail.${your_domain}.
ns1.${your_domain}.         IN      A       $system_ip
mail.${your_domain}.        IN      A       $system_ip
test.${your_domain}.        IN      A       $system_ip
EOT
}

systemctl status named 2>/tmp/check_error.txt 1>/tmp/check_status.txt
if grep -Fxq 'Unit named.service could not be found.' /tmp/check_error.txt
then
	echo -n "Named service is not installed on your system, starting installing "
	for i in `seq 1 5`
	do
		echo -n '.'
		sleep 1
	done
	echo
	yum -y install bind*
	systemctl start named
	systemctl enable named
	echo -e "\e[32mNamed service has been installed and enabled\e[0m"
	systemctl status named
	sleep 5
	
	cp /etc/named.conf  /etc/named.bak #backup file config

	sed -i 's/\tlisten-on port/\/\/\tlisten-on port/; s/\tlisten-on-v6/\/\/\tlisten-on-v6/' /etc/named.conf
	sed -i '/allow-query/ c\\tallow-query\t{ any; };' /etc/named.conf
	
fi


if grep -q "Active: inactive (dead)" /tmp/check_status.txt
then
	systemctl start named
fi

while true
do
	echo -n "Do you want to create a domain? (y/n): "
	read create_domain
	if [ "$create_domain" = "y" ]
	then
		echo -n "Type your desired domain (example.com): "
		read your_domain
		echo -e "\nzone \"$your_domain\" IN {\n\ttype master;\n\tfile \"${your_domain}.db\";\n};\n" >> /etc/named.rfc1912.zones
		echo "Created a zone for your domain. path to /var/named/${your_domain}.db"
#		echo -e "\$TTL 1D\n\@\tIN SOA  ns1.${your_domain}. root.${your_domain}. (\n\t\t\t\t\t1\t\; serial\n\t\t\t\t\t1D\t\; refresh\n\t\t\t\t\t1H\t\; retry\n\t\t\t\t\t1W\t\; expire\n\t\t\t\t\t3H )\t\; minimum\n"
		forward_file #call forward_file function
		break
	elif [ "$create_domain" = "n" ]
	then
		break
	else
		echo "Please type y or n"
	fi
done
systemctl restart named

echo "Goodbye!"
