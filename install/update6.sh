#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [ ! -d /www/server/panel/BTPanel ];then
	echo "============================================="
	echo "错误, 5.x不可以使用此命令升级!"
	echo "5.9平滑升级到6.0的命令：curl http://download.bt.cn/install/update_to_6.sh|bash"
	exit 0;
fi

download_Url='https://github.com/PagodaPanel/Pagoda/raw/master'

Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
if [ "${Centos8Check}" ];then
	if [ ! -f "/usr/bin/python" ] && [ -f "/usr/bin/python3" ] && [ ! -d "/www/server/panel/pyenv" ]; then
		ln -sf /usr/bin/python3 /usr/bin/python
	fi
fi

mypip="pip"
env_path=/www/server/panel/pyenv/bin/activate
if [ -f $env_path ];then
	mypip="/www/server/panel/pyenv/bin/pip"
fi


setup_path='/www'
version='7.7.0'
wget -T 5 -O /tmp/panel.zip https://github.com/PagodaPanel/LinuxPanel/archive/${version}.zip
dsize=$(du -b /tmp/panel.zip|awk '{print $1}')
if [ $dsize -lt 10240 ];then
	echo "获取更新包失败，请稍后更新"
	exit;
fi

/usr/bin/chattr -i /www/server/panel/install/public.sh
/usr/bin/chattr -i /www/server/panel/install/check.sh
unzip -o /tmp/panel.zip -d ${setup_path}/server/ > /dev/null
cd ${setup_path}/server/LinuxPanel-${version}/data
ls | grep -v "warning\|js_random.pl\|licenes.pl\|node.json\|repair.json\|softList.conf\|not_" | xargs rm -rf
cp -R ${setup_path}/server/LinuxPanel-${version}/* ${setup_path}/server/panel
rm -rf ${setup_path}/server/LinuxPanel-${version}

wget -O /www/server/panel/install/public.sh ${download_Url}/install/public.sh -T 10
wget -O /www/server/panel/install/check.sh ${download_Url}/tools/check.sh -T 10
/usr/bin/chattr +i /www/server/panel/install/public.sh
/usr/bin/chattr +i /www/server/panel/install/check.sh
alias chattr='echo skipped chattr'
if grep -q -- "alias chattr=" ~/.bashrc ; then
    echo "alias chattr='echo skipped chattr'" >> ~/.bashrc
    source ~/.bashrc
fi

if [ ! -f /www/server/panel/data/userInfo.json ]; then
    echo "{\"uid\":1000,\"username\":\"admin\",\"serverid\":1}" > /www/server/panel/data/userInfo.json
fi

cd $setup_path/server/panel/
check_bt=`cat /etc/init.d/bt`
if [ "${check_bt}" = "" ];then
	rm -f /etc/init.d/bt
	wget -O /etc/init.d/bt $download_Url/install/src/bt6.init -T 20
	chmod +x /etc/init.d/bt
fi
rm -f /www/server/panel/*.pyc
rm -f /www/server/panel/class/*.pyc
#pip install flask_sqlalchemy
#pip install itsdangerous==0.24

pip_list=$($mypip list)
request_v=$(echo "$pip_list"|grep requests)
if [ "$request_v" = "" ];then
	$mypip install requests
fi
openssl_v=$(echo "$pip_list"|grep pyOpenSSL)
if [ "$openssl_v" = "" ];then
	$mypip install pyOpenSSL
fi

#cffi_v=$(echo "$pip_list"|grep cffi|grep 1.12.)
#if [ "$cffi_v" = "" ];then
#	$mypip install cffi==1.12.3
#fi

pymysql=$(echo "$pip_list"|grep pymysql)
if [ "$pymysql" = "" ];then
	$mypip install pymysql
fi

pymysql=$(echo "$pip_list"|grep pycryptodome)
if [ "$pymysql" = "" ];then
	$mypip install pycryptodome
fi

#psutil=$(echo "$pip_list"|grep psutil|awk '{print $2}'|grep '5.7.')
#if [ "$psutil" = "" ];then
#	$mypip install -U psutil
#fi

if [ -d /www/server/panel/class/BTPanel ];then
	rm -rf /www/server/panel/class/BTPanel
fi

chattr -i /etc/init.d/bt
chmod +x /etc/init.d/bt
echo "====================================="
rm -f /dev/shm/bt_sql_tips.pl
kill $(ps aux|grep -E "task.pyc|main.py"|grep -v grep|awk '{print $2}')
/etc/init.d/bt start
echo 'True' > /www/server/panel/data/restart.pl
pkill -9 gunicorn &
echo "已成功升级到[$version]${Ver}";


