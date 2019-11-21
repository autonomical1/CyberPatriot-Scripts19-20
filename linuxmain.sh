#/bin/bash
if [ "$EUID" -ne 0 ] ;
	then echo "Run as Root"
	exit
fi
zeroUidFun(){
	printf "\033[1;31mChecking for 0 UID users...\033[0m\n"
	#--------- Check and Change UID's of 0 not Owned by Root ----------------
	touch /zerouidusers
	touch /uidusers

	cut -d: -f1,3 /etc/passwd | egrep ':0$' | cut -d: -f1 | grep -v root > /zerouidusers

	if [ -s /zerouidusers ]
	then
		echo "There are Zero UID Users! I'm fixing it now!"

		while IFS='' read -r line || [[ -n "$line" ]]; do
			thing=1
			while true; do
				rand=$(( ( RANDOM % 999 ) + 1000))
				cut -d: -f1,3 /etc/passwd | egrep ":$rand$" | cut -d: -f1 > /uidusers
				if [ -s /uidusers ]
				then
					echo "Couldn't find unused UID. Trying Again... "
				else
					break
				fi
			done
			usermod -u $rand -g $rand -o $line
			touch /tmp/oldstring
			old=$(grep "$line" /etc/passwd)
			echo $old > /tmp/oldstring
			sed -i "s~0:0~$rand:$rand~" /tmp/oldstring
			new=$(cat /tmp/oldstring)
			sed -i "s~$old~$new~" /etc/passwd
			echo "ZeroUID User: $line"
			echo "Assigned UID: $rand"
		done < "/zerouidusers"
		update-passwd
		cut -d: -f1,3 /etc/passwd | egrep ':0$' | cut -d: -f1 | grep -v root > /zerouidusers

		if [ -s /zerouidusers ]
		then
			echo "WARNING: UID CHANGE UNSUCCESSFUL!"
		else
			echo "Successfully Changed Zero UIDs!"
		fi
	else
		echo "No Zero UID Users"
	fi
	cont
}
rootCronFun(){
	printf "\033[1;31mChanging cron to only allow root access...\033[0m\n"
	
	#--------- Allow Only Root Cron ----------------
	#reset crontab
	crontab -r
	cd /etc/
	/bin/rm -f cron.deny at.deny
	echo root >cron.allow
	echo root >at.allow
	/bin/chown root:root cron.allow at.allow
	/bin/chmod 644 cron.allow at.allow
	cont
}
apacheSecFun(){
	printf "\033[1;31mSecuring Apache...\033[0m\n"
	#--------- Securing Apache ----------------
	a2enmod userdir

	chown -R root:root /etc/apache2
	chown -R root:root /etc/apache

	if [ -e /etc/apache2/apache2.conf ]; then
		echo "<Directory />" >> /etc/apache2/apache2.conf
		echo "        AllowOverride None" >> /etc/apache2/apache2.conf
		echo "        Order Deny,Allow" >> /etc/apache2/apache2.conf
		echo "        Deny from all" >> /etc/apache2/apache2.conf
		echo "</Directory>" >> /etc/apache2/apache2.conf
		echo "UserDir disabled root" >> /etc/apache2/apache2.conf
	fi

	systemctl restart apache2.service
	cont
}
function main {
    #variable assignment
    now="$(date +'%d/%m/%Y %r')"
    #intro
    echo "running main ($now)"
    echo "run as 'sudo sh harrisburg-linux.sh 2>&1 | tee output.log' to output the console output to a log file."
    #manual config edits
    nano /etc/apt/sources.list #check for malicious sources
    nano /etc/resolv.conf #make sure if safe, use 8.8.8.8 for name server
    nano /etc/hosts #make sure is not redirecting
    nano /etc/rc.local #should be empty except for 'exit 0'
    nano /etc/sysctl.conf #change net.ipv4.tcp_syncookies entry from 0 to 1
    nano /etc/lightdm/lightdm.conf #allow_guest=false, remove autologin
    nano /etc/ssh/sshd_config #Look for PermitRootLogin and set to no
    #installs
    apt-get -V -y install firefox hardinfo chkrootkit iptables portsentry lynis ufw gufw sysv-rc-conf nessus clamav
    apt-get -V -y install --reinstall coreutils
    apt-get update
    apt-get upgrade
    apt-get dist-upgrade
    #network security
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 23 -j DROP         #Block Telnet
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 2049 -j DROP       #Block NFS
    iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 2049 -j DROP       #Block NFS
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 6000:6009 -j DROP  #Block X-Windows
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 7100 -j DROP       #Block X-Windows font server
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 515 -j DROP        #Block printer port
    iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 515 -j DROP        #Block printer port
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 111 -j DROP        #Block Sun rpc/NFS
    iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 111 -j DROP        #Block Sun rpc/NFS
    iptables -A INPUT -p all -s localhost  -i eth0 -j DROP            #Deny outside packets from internet which claim to be from your loopback interface.
    ufw enable
    ufw deny 23
    ufw deny 2049
    ufw deny 515
    ufw deny 111
    lsof  -i -n -P
    netstat -tulpn
    #media file deletion
    find / -name '*.mp3' -type f -delete
    find / -name '*.mov' -type f -delete
    find / -name '*.mp4' -type f -delete
    find / -name '*.avi' -type f -delete
    find / -name '*.mpg' -type f -delete
    find / -name '*.mpeg' -type f -delete
    find / -name '*.flac' -type f -delete
    find / -name '*.m4a' -type f -delete
    find / -name '*.flv' -type f -delete
    find / -name '*.ogg' -type f -delete
    find /home -name '*.gif' -type f -delete
    find /home -name '*.png' -type f -delete
    find /home -name '*.jpg' -type f -delete
    find /home -name '*.jpeg' -type f -delete
    #information gathering
    hardinfo -r -f html 
    chkrootkit 
    lynis -c 
    freshclam
    clamscan -r /
    echo "remember to do user management, gui related configurations, set automatic updates/security updates, etc."
    echo "thank you for using harrisburg-linux.sh ($now)"
    now="$(date +'%d/%m/%Y %r')" #update date/time
}

if [ "$(id -u)" != "0" ]; then
    echo "harrisburg-linux.sh is not being run as root"
    echo "run as 'sudo sh harrisburg-linux.sh 2>&1 | tee output.log' to output the console output to a log file."
    exit
else
    main
fi
function main {
    #variable assignment
    now="$(date +'%d/%m/%Y %r')"
    #intro
    echo "running main ($now)"
    echo "run as 'sudo sh harrisburg-linux.sh 2>&1 | tee output.log' to output the console output to a log file."
    #manual config edits
    nano /etc/apt/sources.list #check for malicious sources
    nano /etc/resolv.conf #make sure if safe, use 8.8.8.8 for name server
    nano /etc/hosts #make sure is not redirecting
    nano /etc/rc.local #should be empty except for 'exit 0'
    nano /etc/sysctl.conf #change net.ipv4.tcp_syncookies entry from 0 to 1
    nano /etc/lightdm/lightdm.conf #allow_guest=false, remove autologin
    nano /etc/ssh/sshd_config #Look for PermitRootLogin and set to no
    #installs
    apt-get -V -y install firefox hardinfo chkrootkit iptables portsentry lynis ufw gufw sysv-rc-conf nessus clamav
    apt-get -V -y install --reinstall coreutils
    apt-get update
    apt-get upgrade
    apt-get dist-upgrade
    #network security
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 23 -j DROP         #Block Telnet
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 2049 -j DROP       #Block NFS
    iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 2049 -j DROP       #Block NFS
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 6000:6009 -j DROP  #Block X-Windows
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 7100 -j DROP       #Block X-Windows font server
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 515 -j DROP        #Block printer port
    iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 515 -j DROP        #Block printer port
    iptables -A INPUT -p tcp -s 0/0 -d 0/0 --dport 111 -j DROP        #Block Sun rpc/NFS
    iptables -A INPUT -p udp -s 0/0 -d 0/0 --dport 111 -j DROP        #Block Sun rpc/NFS
    iptables -A INPUT -p all -s localhost  -i eth0 -j DROP            #Deny outside packets from internet which claim to be from your loopback interface.
    ufw enable
    ufw deny 23
    ufw deny 2049
    ufw deny 515
    ufw deny 111
    lsof  -i -n -P
    netstat -tulpn
    #media file deletion
    find / -name '*.mp3' -type f -delete
    find / -name '*.mov' -type f -delete
    find / -name '*.mp4' -type f -delete
    find / -name '*.avi' -type f -delete
    find / -name '*.mpg' -type f -delete
    find / -name '*.mpeg' -type f -delete
    find / -name '*.flac' -type f -delete
    find / -name '*.m4a' -type f -delete
    find / -name '*.flv' -type f -delete
    find / -name '*.ogg' -type f -delete
    find /home -name '*.gif' -type f -delete
    find /home -name '*.png' -type f -delete
    find /home -name '*.jpg' -type f -delete
    find /home -name '*.jpeg' -type f -delete
    #information gathering
    hardinfo -r -f html 
    chkrootkit 
    lynis -c 
    freshclam
    clamscan -r /
    echo "remember to do user management, gui related configurations, set automatic updates/security updates, etc."
    now="$(date +'%d/%m/%Y %r')" #update date/time
}

if [ "$(id -u)" != "0" ]; then
    echo "linuxmain.sh is not being run as root"
    echo "run as 'sudo sh linuxmain.sh 2>&1 | tee output.log' to output the console output to a log file."
    exit
else
    main
fi
sysCtlFun(){
	printf "\033[1;31mMaking Sysctl Secure...\033[0m\n"
	#--------- Secure /etc/sysctl.conf ----------------
	sysctl -w net.ipv4.tcp_syncookies=1
	sysctl -w net.ipv4.ip_forward=0
	sysctl -w net.ipv4.conf.all.send_redirects=0
	sysctl -w net.ipv4.conf.default.send_redirects=0
	sysctl -w net.ipv4.conf.all.accept_redirects=0
	sysctl -w net.ipv4.conf.default.accept_redirects=0
	sysctl -w net.ipv4.conf.all.secure_redirects=0
	sysctl -w net.ipv4.conf.default.secure_redirects=0
	sysctl -p
	cont
}
scanFun(){
	printf "\033[1;31mScanning for Viruses...\033[0m\n"
	#--------- Scan For Vulnerabilities and viruses ----------------

	#chkrootkit
	printf "\033[1;31mStarting CHKROOTKIT scan...\033[0m\n"
	chkrootkit -q
	cont

	#Rkhunter
	printf "\033[1;31mStarting RKHUNTER scan...\033[0m\n"
	rkhunter --update
	rkhunter --propupd #Run this once at install
	rkhunter -c --enable all --disable none
	cont
	
	#Lynis
	printf "\033[1;31mStarting LYNIS scan...\033[0m\n"
	cd /usr/share/lynis/
	/usr/share/lynis/lynis update info
	/usr/share/lynis/lynis audit system
	cont
	
	#ClamAV
	printf "\033[1;31mStarting CLAMAV scan...\033[0m\n"
	systemctl stop clamav-freshclam
	freshclam --stdout
	systemctl start clamav-freshclam
	clamscan -r -i --stdout --exclude-dir="^/sys" /
	cont
}
echo Do you need samba?
read sambaYN
if [ $sambaYN == no ]
then
	ufw deny netbios-ns
	ufw deny netbios-dgm
	ufw deny netbios-ssn
	ufw deny microsoft-ds
	apt-get purge samba -y -qq
	apt-get purge samba-common -y  -qq
	apt-get purge samba-common-bin -y -qq
	apt-get purge samba4 -y -qq
	clear
	printTime "netbios-ns, netbios-dgm, netbios-ssn, and microsoft-ds ports have been denied. Samba has been removed."
elif [ $sambaYN == yes ]
then
	ufw allow netbios-ns
	ufw allow netbios-dgm
	ufw allow netbios-ssn
	ufw allow microsoft-ds
	apt-get install samba -y -qq
	apt-get install system-config-samba -y -qq
	cp /etc/samba/smb.conf ~/Desktop/backups/
	if [ "$(grep '####### Authentication #######' /etc/samba/smb.conf)"==0 ]
	then
		sed -i 's/####### Authentication #######/####### Authentication #######\nsecurity = user/g' /etc/samba/smb.conf
	fi
	sed -i 's/usershare allow guests = no/usershare allow guests = yes/g' /etc/samba/smb.conf
	
	echo Type all user account names, with a space in between
	read -a usersSMB
	usersSMBLength=${#usersSMB[@]}	
	for (( i=0;i<$usersSMBLength;i++))
	do
		echo -e 'Moodle!22\nMoodle!22' | smbpasswd -a ${usersSMB[${i}]}
		printTime "${usersSMB[${i}]} has been given the password 'Moodle!22' for Samba."
	done
	printTime "netbios-ns, netbios-dgm, netbios-ssn, and microsoft-ds ports have been denied. Samba config file has been configured."
	clear
else
	echo Response not recognized.
fi
printTime "Samba is complete."
echo Do you need FTP?
read ftpYN
if [ $ftpYN == no ]
then
	ufw deny ftp 
	ufw deny sftp 
	ufw deny saft 
	ufw deny ftps-data 
	ufw deny ftps
	apt-get purge vsftpd -y -qq
	printTime "vsFTPd has been removed. ftp, sftp, saft, ftps-data, and ftps ports have been denied on the firewall."
elif [ $ftpYN == yes ]
then
	ufw allow ftp 
	ufw allow sftp 
	ufw allow saft 
	ufw allow ftps-data 
	ufw allow ftps
	cp /etc/vsftpd/vsftpd.conf ~/Desktop/backups/
	cp /etc/vsftpd.conf ~/Desktop/backups/
	gedit /etc/vsftpd/vsftpd.conf&gedit /etc/vsftpd.conf
	service vsftpd restart
	printTime "ftp, sftp, saft, ftps-data, and ftps ports have been allowed on the firewall. vsFTPd service has been restarted."
else
	echo Response not recognized.
fi
printTime "FTP is complete."
clear
apt-get purge netcat -y -qq
apt-get purge netcat-openbsd -y -qq
apt-get purge netcat-traditional -y -qq
apt-get purge ncat -y -qq
apt-get purge pnetcat -y -qq
apt-get purge socat -y -qq
apt-get purge sock -y -qq
apt-get purge socket -y -qq
apt-get purge sbd -y -qq
rm /usr/bin/nc
clear
printTime "Netcat and all other instances have been removed."

apt-get purge john -y -qq
apt-get purge john-data -y -qq
clear
printTime "John the Ripper has been removed."

apt-get purge hydra -y -qq
apt-get purge hydra-gtk -y -qq
clear
printTime "Hydra has been removed."

apt-get purge aircrack-ng -y -qq
clear
printTime "Aircrack-NG has been removed."

apt-get purge fcrackzip -y -qq
clear
printTime "FCrackZIP has been removed."

apt-get purge lcrack -y -qq
clear
printTime "LCrack has been removed."

apt-get purge ophcrack -y -qq
apt-get purge ophcrack-cli -y -qq
clear
printTime "OphCrack has been removed."

apt-get purge pdfcrack -y -qq
clear
printTime "PDFCrack has been removed."

apt-get purge pyrit -y -qq
clear
printTime "Pyrit has been removed."

apt-get purge rarcrack -y -qq
clear
printTime "RARCrack has been removed."

apt-get purge sipcrack -y -qq
clear
printTime "SipCrack has been removed."

apt-get purge irpas -y -qq
clear
printTime "IRPAS has been removed."

clear
printTime 'Are there any hacking tools shown? (not counting libcrack2:amd64 or cracklib-runtime)'
dpkg -l | egrep "crack|hack" >> ~/Desktop/Script.log
			#torrenting programs
		clear
			echo "Clearing Unwanted Programs"	
			#Remove Torrenting programs
		sudo apt-get purge qbittorrent 
		sudo apt-get purge utorrent 
		sudo apt-get purge ctorrent 
		sudo apt-get purge ktorrent 
		sudo apt-get purge rtorrent 
		sudo apt-get purge deluge 
		sudo apt-get purge transmission-gtk
		sudo apt-get purge transmission-common 
		sudo apt-get purge tixati 
		sudo apt-get purge frostwise 
		sudo apt-get purge vuze 
		sudo apt-get purge irssi
		sudo apt-get purge talk 
		sudo apt-get purge telnet
			#Remove pentesting
		sudo apt-get purge wireshark 
		sudo apt-get purge nmap 
		sudo apt-get purge john 
		sudo apt-get purge netcat 
		sudo apt-get purge netcat-openbsd 
		sudo apt-get purge netcat-traditional 
		sudo apt-get purge netcat-ubuntu 
		sudo apt-get purge netcat-minimal
			#cleanup	 
		sudo apt-get autoremove

