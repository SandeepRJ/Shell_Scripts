#!/bin/bash

ulimit -Hs 10000

echo 'unset HISTFILE' >> ~/.bash_profile
echo 'set +o history' >> ~/.bash_profile
bash ~/.bash_profile

#Install curl on Debian/ ubuntu
#Ref: https://stackoverflow.com/questions/26988262/best-way-to-find-os-name-and-version-in-unix-linux-platform
#One can perform a check for the OS distribution and run commands according to the OS distribution
OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`

GetVersionFromFile()
{
    VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ // `
}

if [ "${OS}" = "SunOS" ] ; then
    OS=Solaris
    ARCH=`uname -p` 
    OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    DIST="Solaris"
elif [ "${OS}" = "AIX" ] ; then
    OSSTR="${OS} `oslevel` (`oslevel -r`)"
    DIST="AIX"
elif [ "${OS}" = "Linux" ] ; then
    KERNEL=`uname -r`
    if [ -f /etc/redhat-release ] ; then
        DIST='RedHat'
        PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/SuSE-release ] ; then
        DIST=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
        REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
    elif [ -f /etc/mandrake-release ] ; then
        DIST='Mandrake'
        PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
    elif [ -f /etc/debian_version ] ; then
        DIST="Debian `cat /etc/debian_version`"
        REV=""

    fi
    if [ -f /etc/UnitedLinux-release ] ; then
        DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
    fi
    OSSTR="${OS} ${DIST} ${REV}(${PSUEDONAME} ${KERNEL} ${MACH})"

fi

sudo touch /etc/sysctl.conf
sudo chmod 660 /etc/sysctl.conf
echo 'net.netfilter.nf_conntrack_max = 3097152' | sudo tee -a /etc/sysctl.conf


#If distribution is Ubuntu/Debian then use apt
if [ "${DIST}" == *"Ubuntu"* ] || [ "${DIST}" == *"Debian"* ] ; then
	sudo apt install -y curl
	sudo apt -y update
        sudo apt -y install gcc make wget
	sudo apt install -y redis-server
        sudo sed -i -e 's/port 6379/port 10000/g' /etc/redis/redis.conf
	sudo sed -i -e 's/# requirepass foobared/requirepass test123/g' /etc/redis/redis.conf
	sudo service redis-server start
fi

#For different os distributions
#wget http://download.redis.io/releases/redis-5.0.7.tar.gz
#tar xzf redis-5.0.7.tar.gz
#rm redis-5.0.7.tar.gz
#cd redis-5.0.7
#make distclean
#make
#echo "REDIS_HOME='~/redis-5.0.7'" >> ~/.bash_profile
#echo "export PATH=$PATH:$REDIS_HOME/bin" >> ~/.bash_profile


#sudo make
#echo "REDIS_HOME='~/redis-5.0.7'" >> ~/.bashrc
#echo "export PATH=$PATH:$REDIS_HOME/bin" >> ~/.bashrc


#Monitoring
for (( ; ; ))
do
   sleep 3
   NOW=$(date +"%d-%m-%Y")
   if (pgrep -x "redis-server")
   then
        echo "redis is running - $NOW"
        logger "redis is running - $NOW" || :
        NOW=$(date +"%d-%m-%Y")
        if (echo set foo \"This is a single argument\" | redis-cli -h 127.0.0.1 -p 10000 -a test123)
        then
                echo "Write success to redis - $NOW"
                logger "Write success to redis - $NOW" || :
        else
                echo "Write failure to redis - $NOW"
                logger "Write failure to redis - $NOW" || :
        fi
   else
        echo "redis is stopped - $NOW"
        logger "redis is stopped - $NOW" || :
        echo "Write failure to redis - $NOW"
        logger "Write failure to redis - $NOW" || :
   fi
done

