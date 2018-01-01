# AUTHOR	: Des McCarter
# DESCRIPTION	: RBPI-3 PROJECTS

# INIT

	1. Before the rasberry is exposed (via wifi) change BOTH the pi and root passwords using 'passwd'.
	2. Copy the contents of linux/etc/network/interfaces to /etc/network/interfaces, using the actual WIFI crednetials
	3. Create a /boot/ssh file (doesn't matter if it contains anything) 
	4. Reboot the pi and it should be exposed externally and accessible via SSH

# Expose folder to windows
	
	Install Samba
	
	sudo apt-get update
	sudo apt-get install samba
	
	Set a password for your user in Samba
	
	sudo smbpasswd -a <user_name>
	
	Note: Samba uses a separate set of passwords than the standard Linux system accounts (stored in /etc/samba/smbpasswd), so you'll need to create a Samba password for yourself. This tutorial implies that you will use your own user and it does not cover situations involving other users passwords, groups, etc...
	Tip1: Use the password for your own user to facilitate.
	Tip2: Remember that your user must have permission to write and edit the folder you want to share.
	Eg.:
	sudo chown <user_name> /var/opt/blah/blahblah
	sudo chown :<user_name> /var/opt/blah/blahblah
	Tip3: If you're using another user than your own, it needs to exist in your system beforehand, you can create it without a shell access using the following command :
	sudo useradd USERNAME --shell /bin/false
	
	You can also hide the user on the login screen by adjusting lightdm's configuration, in /etc/lightdm/users.conf add the newly created user to the line :
	hidden-users=
	Create a directory to be shared
	
	mkdir /home/<user_name>/<folder_name>
	
	Make a safe backup copy of the original smb.conf file to your home folder, in case you make an error
	
	sudo cp /etc/samba/smb.conf ~
	
	Edit the file "/etc/samba/smb.conf"
	
	sudo nano /etc/samba/smb.conf
	
	Once "smb.conf" has loaded, add this to the very end of the file:
	
	[<folder_name>]
	path = /home/<user_name>/<folder_name>
	valid users = <user_name>
	read only = no
	Tip: There Should be in the spaces between the lines, and note que also there should be a single space both before and after each of the equal signs.
	Restart the samba:
	
	sudo service smbd restart
	
	Once Samba has restarted, use this command to check your smb.conf for any syntax errors
	
	testparm
	
	To access your network share
	
	      sudo apt-get install smbclient
	      # List all shares:
	      smbclient -L //<HOST_IP_OR_NAME>/<folder_name> -U <user>
	      # connect:
	      smbclient //<HOST_IP_OR_NAME>/<folder_name> -U <user>
	
	To access your network share use your username (<user_name>) and password through the path "smb://<HOST_IP_OR_NAME>/<folder_name>/" (Linux users) or "\\<HOST_IP_OR_NAME>\<folder_name>\" (Windows users). Note that "<folder_name>" value is passed in "[<folder_name>]", in other words, the share name you entered in "/etc/samba/smb.conf".
	
	Note: The default user group of samba is "WORKGROUP".
	
		Use https://unix.stackexchange.com/questions/206309/how-to-create-a-samba-share-that-is-writable-from-windows-without-777-permission/206310
