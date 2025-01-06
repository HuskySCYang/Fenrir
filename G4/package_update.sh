
 
	cat os_info.log | grep -i ubuntu >/dev/null
	pip3 install redfishtool
	pip3 install --upgrade urllib3
	pip3 install --upgrade requests
	pip3 install nautilus
	pip3 install robotframework
	pip3 install pyserial-3.4-py2.py3-none-any.whl
	cat os_info.log | grep -i ubuntu > /dev/null
	if [ "$?" == 0 ]; then
		apt install jq -y
		apt install ipmitool -y
		apt install gawk -y
		apt install fence* -y
		apt install ipmiutil -y
		apt install rasdaemon -y
		apt install nautilus -y
		apt install smartmontools -y
		apt install lsscsi* -y
		apt install ethtool -y
	else
		yum install jq -y
		yum install ipmitool -y
		yum install fence* -y
		yum install nautilus -y
		yum install gawk -y
		yum install ipmiutil -y
		yum install nautilus -y
		yum install rasdaemon -y
		#yum install smartmontools -y
	        yum install lsscsi* -y
		# install ipmiutil
		if [ "$(rpm -qa | grep -i ipmiutil)" == "" ];then
		rpm -ivh ipmiutil-3.1.8-1_el8.x86_64.rpm
		fi
	fi

