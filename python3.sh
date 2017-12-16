#!/usr/bin/env bash
#
# Auto install Python3
#
# Copyright (C) 2017 evrmji
# Thanks:
# https://teddysun.com
#
# System Required:  CentOS 6+

clear
echo "---------------------------------------"
echo "  Install Python3 for CENTOS\REHL 6+   "
echo "                                       "
echo "  System Required:  CentOS 6+          "
echo "---------------------------------------"
echo "  USER: $USER   HOST: $HOSTNAME" 
echo "  KERNEL: `uname -r`"
echo "--------------------------------------" 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

cur_dir=$( pwd )

python3_url="https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tar.xz"
python3_file="Python-3.6.3"

get_char() {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

detect_depends(){
    local command=$1
    local depend=`echo "${command}" | awk '{print $4}'`
    ${command}
    if [ $? != 0 ]; then
        echo -e "[${red}Error${plain}] Failed to install ${red}${depend}${plain}"
        exit 1
    fi
}

depends_install(){
    echo -e "[${green}Info${plain}] Install depends.."
        yum_depends=(
            zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
        )
        for depend in ${yum_depends[@]}; do
            detect_depends "yum -y -q install ${depend}"
        done
}

download() { 
    local filename=$(basename $1)
    if [ -f ${1} ]; then
        echo "[${green}Info${plain}] ${filename} [${green}found${plain}]"
   else
        echo "[${green}Info${plain}] ${filename} not found, download now..."
        wget --no-check-certificate -c -t3 -T60 -O ${1} ${2}
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Download ${filename} failed."
            exit 1
        fi
    fi
}

download_files(){
    download "${python3_file}.tar.xz" "${python3_url}"
}

install_start(){
    download_files
    tar vxf ${python3_file}.tar.xz &> /dev/null && echo  -e  "[${green}Success${plain}]" || echo -e "[${red}Failed${plain}]"
    cd ${python3_file}
    ./configure --prefix=/usr/local/${python3_file}
    make -j 8
    make install
    if [ $? -ne 0 ]; then
        echo -e "[${red}Failed${plain}] ${python3_file} install failed."
        exit 1
    else
        echo -e "[${green}Success${plain}] ${python3_file}  install finish."
    fi
    ln -s /usr/local/${python3_file}/bin/pip3  /usr/bin/pip3
    ln -s /usr/local/${python3_file}/bin/python3 /usr/bin/python3
    echo "PATH=/usr/local/${python3_file}/bin/:\$PATH " >> /etc/profile
    echo "PYTHONPATH=\$PYTHONPATH:/usr/local/p${python3_file}/lib/python3/" >> /etc/profile
    source /etc/profile
    if [ $? -ne 0 ]; then
        echo -e "[${red}Failed${plain}] ${python3_file} link failed."
        exit 1
    else
        echo -e "[${green}Success${plain}] ${python3_file}  link finish."
    fi

}

install_finish(){
    V3 = `python3 -V | awk '{print $2}'`
    echo "[${green}info${plain}] Python Version: $V3 "
    echo "You can input \"python3\" to enter ${python3_file} and input \"pip3\" to manage your python3 packages."

}

install_python(){
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`
    depends_install
    install_start
    install_finish
}

install_python

