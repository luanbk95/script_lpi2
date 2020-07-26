#/bin/bash

modify_to_samba_config () {

sed -i '/\[global\]/,+16d' /etc/samba/smb.conf
cat <<OEF >> /etc/samba/smb.conf

[global]
	workgroup = WORKGROUP
	server string = Samba Server %v
	security = user
	map to guest = bad user
	dns proxy = no

OEF

}

insert_to_samba_config () {
cat <<OEF >> /etc/samba/smb.conf

[$shared_directory]
	comment = $shared_directory File Server Share
	path =  /srv/samba/${shared_directory}
	valid users = @$group_name
	guest ok = no
	writable = yes
	browsable = yes

OEF

}
#check status of samba service
systemctl status smb 1>/tmp/check_status 2>/tmp/check_error
if grep -Fxq "Unit smb.service could not be found." /tmp/check_error
then
	echo -n "Samba service is not installed on your system, starting installing "
	for i in `seq 1 5`
	do
		echo -n '.'
		sleep 1
	done
	echo
	yum install -y samba samba-client samba-common

	
	#backup file config of samba
	cp /etc/samba/smb.conf /etc/samba/smb.conf.bak


	modify_to_samba_config

	echo -n "Please type directory's name you would like to share: "
	read shared_directory

	
	#create group and user for credentials
	echo -n "Type group name for credentials: "
	read group_name
	
	echo -n "Type user name for credentials: "
	read user_name

	echo -n "Type samba passwd for above user: "
	read pass_user

	groupadd $group_name
	useradd $user_name
	usermod $user_name -aG $group_name


	mkdir -p /srv/samba/${shared_directory}
	chmod -R 0777 /srv/samba/${shared_directory}
	chown -R root:$group_name /srv/samba/${shared_directory}


	(echo "$pass_user"; echo "$pass_user") | smbpasswd -s -a $user_name
##	echo -e "$pass_user\n$pass_user" | smbpasswd $user_name
##	echo "$pass_user" | smbpasswd --stdin -a $user_name

	insert_to_samba_config

	systemctl restart smb
	systemctl restart nmb
	systemctl enable smb
	systemctl enable nmb
	echo
	echo -e "\e[32mYour samba service has been installled and enabled"
	echo "Credentails (username/password): $user_name/$pass_user in group $group_name"
	echo -e "Shared directory located on /srv/samba/${shared_directory}\e[0m"
fi

if grep -q "Active: inactive (dead)" /tmp/check_status
then
	systemctl start smb
fi

rm -rf /tmp/check_status
rm -rf /tmp/check_error
