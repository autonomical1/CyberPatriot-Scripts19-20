#/bin/bash
# Check if script is run with root
if [[ $EUID -ne 0 ]]
then
  echo "Please run again as root using 'sudo ./linuxmain.sh'"
  exit 1
fi
# Install rootkits, anti-malware, etc..
sudo apt-get install chkrootkit 
sudo apt-get install ufw 
sudo apt-get install clamav 
sudo apt-get install rkhunter 
sudo apt-get install selinux 
sudo apt-get install tree
sudo apt-get install auditd 
sudo apt-get install bum 
sudo apt-get install htop
sudo apt-get install symlinks
clear
# Use those rootkits, anti-malware, etc...
sudo chkrootkit
sudo freshclam
sudo clamscan -r /
# Firewall
sudo ufw enable
ufw deny 23
ufw deny 2049
ufw deny 515
ufw deny 111
ufw deny 7100
# Updates
sudo apt-get -y upgrade
sudo apt-get -y update
sudo add-apt-repository -y ppa:libreoffice/ppa
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
killall firefox
sudo apt-get --purge --reinstall install firefox -y
sudo apt-get install clamtk -y

# Lock Out Root User
sudo passwd -l root

# Disable Guest Account
echo "allow-guest=false" >> /etc/lightdm/lightdm.conf

# Password Policy Configuration
sudo sed -i '/^PASS_MAX_DAYS/ c\PASS_MAX_DAYS   90' /etc/login.defs
sudo sed -i '/^PASS_MIN_DAYS/ c\PASS_MIN_DAYS   10'  /etc/login.defs
sudo sed -i '/^PASS_WARN_AGE/ c\PASS_WARN_AGE   7' /etc/login.defs

# Force Strong Passwords
sudo apt-get -y install libpam-cracklib
sudo sed -i '1 s/^/password requisite pam_cracklib.so retry=3 minlen=8 difok=3 reject_username minclass=3 maxrepeat=2 dcredit=1 ucredit=1 lcredit=1 ocredit=1\n/' /etc/pam.d/common-password

# MySQL
echo -n "MySQL [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  sudo apt-get -y install mysql-server
  # Disable remote access
  sudo sed -i '/bind-address/ c\bind-address = 127.0.0.1' /etc/mysql/my.cnf
  sudo service mysql restart
else
  sudo apt-get -y purge mysql*
fi

# OpenSSH Server; Edit ssh/sshd_config
echo -n "OpenSSH Server [Y/n] "
read option
if [[ $option =~ ^[Yy]$ ]]
then
  sudo apt-get -y install openssh-server
  # Disable root login
  sudo sed -i '/^PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
  sudo service ssh restart
else
  sudo apt-get -y purge openssh-server*
fi
sed -i -e 's/PasswordAuthentication.*/ PasswordAuthentication yes/' /etc/ssh/sshd_config
    			sed -i -e 's/UsePrivilegeSeparation.*/UsePrivilegeSeparation yes/' /etc/ssh/sshd_config
    			sed -i -e 's/PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    			sed -i -e 's/PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
    			sed -i -e 's/X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
    			sed -i -e 's/UsePam.*/UsePAM yes/' /etc/ssh/sshd_config
    			sed -i -e 's/LogLevel.*/LogLevel INFO/' /etc/ssh/sshd_config
    			sed -i -e 's/MaxAuthTries.*/MaxAuthTries 4' /etc/ssh/sshd_config
    			sed -i -e 's/PermitUserEnvironment.*/PermitUserEnvironment no' /etc/ssh/sshd_config
    			sed -i -e 's/#   ForwardX11.*/#   ForwardX11 no/' /etc/ssh/ssh_config
    			sed -i -e 's/#   Protocol.*/#   Protocol 2/' /etc/ssh/ssh_config
				sed -i -e 's/#   PasswordAuthentication.*/#   PasswordAuthentication yes/' /etc/ssh/ssh_config
				sed -i -e 's/#   PermitLocalCommand.*/#   PermitLocalCommand no/' /etc/ssh/ssh_config
sudo service ssh restart
		sudo service sshd restart


# Remove Hacking Tools

dpkg --get-selections | grep john

dpkg --get-selections | grep crack
# NOTE: CRACKLIB IS GOOD

dpkg --get-selections | grep -i hydra

dpkg --get-selections | grep weplab

dpkg --get-selections | grep pyrit
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


# Media Files
for suffix in mp3 txt wav wma aac mp4 mov avi gif jpg png bmp img exe msi bat sh
do
  sudo find /home -name *.$suffix
done

# Make backups of critical files
mkdir /BackUps
##Backups the sudoers file
sudo cp /etc/sudoers /Backups
##Backups the home directory
cp /etc/passwd /BackUps
##Backups the log files
cp -r /var/log /BackUps
##Backups the passwd file
cp /etc/passwd /BackUps
##Backups the group file
cp /etc/group /BackUps
##Back ups the shadow file
cp /etc/shadow /BackUps
##Backing up the /var/spool/mail
cp /var/spool/mail /Backups
##backups all the home directories
for x in `ls /home`
do
	cp -r /home/$x /BackUps
done

#Set Automatic Updates

##Set daily updates
		sed -i -e 's/APT::Periodic::Update-Package-Lists.*\+/APT::Periodic::Update-Package-Lists "1";/' /etc/apt/apt.conf.d/10periodic
		sed -i -e 's/APT::Periodic::Download-Upgradeable-Packages.*\+/APT::Periodic::Download-Upgradeable-Packages "0";/' /etc/apt/apt.conf.d/10periodic
##Sets default broswer
		sed -i 's/x-scheme-handler\/http=.*/x-scheme-handler\/http=firefox.desktop/g' /home/$UserName/.local/share/applications/mimeapps.list
##Set "install security updates"
		cat /etc/apt/sources.list | grep "deb http://security.ubuntu.com/ubuntu/ trusty-security universe main multiverse restricted"
		if [ $? -eq 1 ]
		then
			echo "deb http://security.ubuntu.com/ubuntu/ trusty-security universe main multiverse restricted" >> /etc/apt/sources.list
		fi

		echo "###Automatic updates###"
		cat /etc/apt/apt.conf.d/10periodic
		echo ""
		echo "###Important Security Updates###"
		cat /etc/apt/sources.list

# Network (sysctl) stuff
sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv4.conf.all.send_redirects=0 
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_source_route=0 
sysctl -w net.ipv4.conf.default.accept_source_route=0
sysctl -w net.ipv4.conf.all.accept_redirects=0 
sysctl -w net.ipv4.conf.default.accept_redirects=0 
sysctl -w net.ipv4.conf.all.secure_redirects=0 
sysctl -w net.ipv4.conf.default.secure_redirects=0
sysctl -w net.ipv4.conf.all.log_martians=1 
sysctl -w net.ipv4.conf.default.log_martians=1
sysctl -w net.ipv4.route.flush=1
sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
sysctl -w net.ipv4.conf.all.rp_filter=1 
sysctl -w net.ipv4.conf.default.rp_filter=1 
sysctl -w net.ipv4.tcp_syncookies=1
sysctl -w net.ipv6.conf.all.accept_ra=0 
sysctl -w net.ipv6.conf.default.accept_ra=0
sysctl -w net.ipv6.conf.all.accept_redirects=0 
sysctl -w net.ipv6.conf.default.accept_redirects=0
    	sysctl -p	

# Resets bash history file (CP likes to disable history)
echo "*Resetting bash history*"
sudo rm ~/.bash_history 


