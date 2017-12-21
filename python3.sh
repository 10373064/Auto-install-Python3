#!/usr/bin/env bash
#
# Auto install Python3
#
# Copyright (C) 2017 evrmji
#
# Thanks:
# https://teddysun.com
# And a lot of things copy from there
# 
# System Required:  CentOS 6+


PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
plain='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] This script must be run as root!" && exit 1

cur_dir=$( pwd )

python3_url="https://www.python.org/ftp/python/3.6.4/Python-3.6.4.tar.xz"
python3_file="Python-3.6.4"
install_path="/usr/local/"

get_char() {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}


detect_depends(){
    if [ get_opsy == 'ubuntu' || get_opsy == 'debian']; then
        apt-get install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
    fi
    if [ get_opsy == 'centos' || get_opsy == 'fedora' || get_opsy == 'rhel']; then
        yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
    fi
    if [ get_opsy == 'archlinux' ]; then
        yaourt install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
    fi
    if [ get_opsy == 'gentoo']; then
        emerge -av denyhosts -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
    fi
    if [ $? != 0 ]; then
        echo -e "[${red}Error${plain}] Failed to install ${red}${depend}${plain}"
        exit 1
    fi
}


download() { 
    local filename=$(basename $1)
    if [ -f ${1} ]; then
        echo -e "[${green}Info${plain}] ${filename} [${green}found${plain}]"
   else
        echo -e "[${green}Info${plain}] ${filename} not found, download now..."
        wget --no-check-certificate -c -t3 -T60 -O ${1} ${2}
        if [ $? -ne 0 ]; then
            echo -e "[${red}Error${plain}] Download ${filename} failed."
            exit 1
        fi
    fi
}

install(){
    download "${python3_file}.tar.xz" "${python3_url}"
    tar vxf ${python3_file}.tar.xz
    cd ${python3_file}
    ./configure --prefix=${install_path}${python3_file}
    make -j4
    make install
    if [ $? -ne 0 ]; then
        echo -e "[${red}Failed${plain}] ${python3_file} install failed."
        exit 1
    else
        echo -e "[${green}Success${plain}] ${python3_file}  install finish."
    fi
    ln -s ${install_path}${python3_file}/bin/pip3  /usr/bin/pip3
    ln -s ${install_path}${python3_file}/bin/python3 /usr/bin/python3
    echo "PATH=${install_path}${python3_file}/bin/:\$PATH " >> /etc/profile
    echo "PYTHONPATH=\$PYTHONPATH:${install_path}${python3_file}/lib/python3/" >> /etc/profile
    source /etc/profile
    rm -fr ${cur_dir}/${python3_file}
    rm -fr ${cur_dir}/${python3_file}.tar.xz
    version=$( python3 --version )
    echo -e "[${green}Info${plain}] Python Version: ${version}"
    echo -e "You can input \"python3\" to enter ${python3_file} and input \"pip3\" to manage your python3 packages."
}

install_python(){
    clear
    echo "---------------------------------------"
    echo " Auto install Python3"
    echo "                                       "
    echo " System Required:  CentOS/REHL 6+,"
    echo "  Debian(untest)"
    echo "------------  Information  ------------"
    echo " User   : $USER   Host: $HOSTNAME" 
    echo " OS     : `get_opsy`"
    echo " Arch   : `uname -m`"
    echo " Kernel : `uname -r`"
    echo "--------------------------------------" 
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

    install
}

uninstall_python(){
    printf "Are you sure uninstall ${red}${python3_file}${plain}? [y/n]\n"
    read -p "(default: n):" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        if check_sys packageManager yum; then
            chkconfig --del ${service_name}
        elif check_sys packageManager apt; then
            update-rc.d -f ${service_name} remove
        fi
        rm -rf ${install_path}${python3_file}
        rm -f /usr/bin/python3
        rm -f /usr/bin/pip3

        echo -e "[${green}Info${plain}] ${python3_file}$ uninstall success"
        echo -e "[${green}Info${plain}] ${red}Something in /etc/profile can't be clean! ${plain}"
    else
        echo
        echo -e "[${green}Info${plain}] ${python3_file}$ uninstall cancelled, nothing to do..."
        echo
    fi
}

action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall)
        ${action}_python
        ;;
    *)
        echo "Arguments error! [${action}]"
        echo "Usage: `basename $0` [install|uninstall]"
        ;;
esac
