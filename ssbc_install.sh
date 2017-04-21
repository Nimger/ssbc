#!/bin/bash
#我本戏子 2016.8
#changelog:
#1.1添加开机自启动功能
#1.2修改pip获取方式
#1.3考虑到精简版系统的情况，自动安装wget与net-tools
#
# 记得修改下面这个代码
# indexer
# {
# 	mem_limit		= 1500M->512M
# }
# 
# 首页JS广告去除
# ssbc-master->web->static->js->ssbc.js->showAds()
# 
# 注释掉所有的document.writeln
# 
python -V          
systemctl stop firewalld.service  
systemctl disable firewalld.service   
systemctl stop iptables.service  
systemctl disable iptables.service  
yum -y install wget
#如果使用linode主机，请取消下面4行的注释
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyuncs.com/repo/Centos-7.repo
#wget -qO /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
#yum clean metadata
#yum makecache
cd ~
wget https://github.com/78/ssbc/archive/master.zip
yum -y install unzip
unzip master.zip
#解压后 源码在/root/ssbc-master目录
yum -y install gcc
yum -y install gcc-c++
yum -y install python-devel
yum -y install mariadb
yum -y install mariadb-devel
yum -y install mariadb-server
cd ssbc-master
yum -y install epel-release
yum -y install  python-pip
pip install -r requirements.txt
pip install  pygeoip
systemctl start  mariadb.service 
mysql -uroot  -e"create database ssbc default character set utf8;"  
sed -i '/!includedir/a\wait_timeout=2880000\ninteractive_timeout = 2880000\nmax_allowed_packet = 512M' /etc/my.cnf
mkdir  -p  /data/bt/index/db /data/bt/index/binlog  /tem/downloads
chmod  755 -R /data
chmod  755 -R /tem
yum -y install unixODBC unixODBC-devel postgresql-libs
wget http://sphinxsearch.com/files/sphinx-2.2.9-1.rhel7.x86_64.rpm
rpm -ivh sphinx-2.2.9-1.rhel7.x86_64.rpm
systemctl restart mariadb.service  
systemctl enable mariadb.service 
searchd --config ./sphinx.conf
python manage.py makemigrations
python manage.py migrate
indexer -c sphinx.conf --all 
ps aux|grep searchd|awk '{print $2}'|xargs kill -9
searchd --config ./sphinx.conf
#启动网站并在后台运行
nohup python manage.py runserver 0.0.0.0:80 >/dev/zero 2>&1&    
yum -y install net-tools
myip=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
while true; do
    read -p "确定浏览器能访问网站  http://$myip  吗?[y/n]" yn
    case $yn in
        [Yy]* ) cd workers; break;;
        [Nn]* ) exit;;
        * ) echo "请输入yes 或 no";;
    esac
done
#运行爬虫并在后台运行
nohup python simdht_worker.py >/dev/zero 2>&1&
#定时索引并在后台运行
nohup python index_worker.py >/dev/zero 2>&1&  
cd ..
python manage.py createsuperuser
#开机自启动
chmod +x /etc/rc.d/rc.local
echo "systemctl start  mariadb.service " >> /etc/rc.d/rc.local
echo "cd /root/ssbc-master " >> /etc/rc.d/rc.local
echo "indexer -c sphinx.conf --all " >> /etc/rc.d/rc.local
echo "searchd --config ./sphinx.conf " >> /etc/rc.d/rc.local
echo "nohup python manage.py runserver 0.0.0.0:80 >/dev/zero 2>&1& " >> /etc/rc.d/rc.local
echo "cd workers " >> /etc/rc.d/rc.local
echo "nohup python simdht_worker.py >/dev/zero 2>&1& " >> /etc/rc.d/rc.local
echo "nohup python index_worker.py >/dev/zero 2>&1& " >> /etc/rc.d/rc.local