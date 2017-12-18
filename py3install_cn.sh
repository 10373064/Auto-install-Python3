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

python3_url="https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tar.xz"
python3_file="Python-3.6.3"
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

check_sys() {
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [ -f /etc/redhat-release ]; then
        release="centos"
        systemPackage="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    fi

    if [ ${checkType} == "sysRelease" ]; then
        if [ "$value" == "$release" ]; then
            return 0
        else
            return 1
        fi
    elif [ ${checkType} == "packageManager" ]; then
        if [ "$value" == "$systemPackage" ]; then
            return 0
        else
            return 1
        fi
    fi
}

detect_depends(){
    local command=$1
    local depend=`echo "${command}" | awk '{print $4}'`
    ${command}
    if [ $? != 0 ]; then
        echo -e "[${red}错误${plain}] 安装 ${red}${depend}${plain}信息"
        exit 1
    fi
}

depends_install(){
    if check_sys packageManager yum; then
        echo -e "[${green}Info${plain}] Checking the EPEL repository..."
        if [ ! -f /etc/yum.repos.d/epel.repo ]; then
            yum install -y -q epel-release
        fi
        [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] Install EPEL repository failed, please check it." && exit 1
        [ ! "$(command -v yum-config-manager)" ] && yum install -y -q yum-utils
        if [ x"`yum-config-manager epel | grep -w enabled | awk '{print $3}'`" != x"True" ]; then
            yum-config-manager --enable epel
        fi
        echo -e "[${green}Info${plain}] Checking the EPEL repository complete..."

        yum_depends=(
            zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
        )
        for depend in ${yum_depends[@]}; do
            detect_depends "yum -y -q install ${depend}"
        done
    elif check_sys packageManager apt; then
        apt_depends=(
            zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc wget make xz
        )
        for depend in ${apt_depends[@]}; do
            detect_depends "apt-get -y install ${depend}"
        done
    fi
}

download() { 
    local filename=$(basename $1)
    if [ -f ${1} ]; then
        echo -e "[${green}信息${plain}] ${filename} [${green}找到${plain}]"
   else
        echo -e "[${green}信息${plain}] 未找到${filename}, 正在下载..."
        wget --no-check-certificate -c -t3 -T60 -O ${1} ${2}
        if [ $? -ne 0 ]; then
            echo -e "[${red}错误${plain}] Download ${filename} failed."
            exit 1
        fi
    fi
}

download_files(){
    download "${python3_file}.tar.xz" "${python3_url}"
}

install_start(){
    download_files
    rm -fr ${cur_dir}/${python3_file}
    echo -e "[${green}信息${plain}] unzip ${python3_file} \c"
    tar vxf ${python3_file}.tar.xz  &> /dev/null && echo  -e  "${green}成功 ...${plain}" || echo -e "${red}失败 ...${plain}"
    cd ${python3_file}
    echo -e "[${green}信息${plain}] prepare compile \c"
    ./configure --prefix=${install_path}${python3_file}  &> /dev/null && echo  -e  "${green}成功 ...${plain}" || echo -e "${red}失败 ...${plain}"
    echo -e "[${green}信息${plain}] compiling \c"
    make -j 4  &> /dev/null && echo  -e  "${green}成功 ...${plain}" || echo -e "${red}失败 ...${plain}"
    echo -e "[${green}信息${plain}] install \c"
    make install -j 4 &> /dev/null && echo  -e  "${green}成功 ...${plain}" || echo -e "${red}失败 ...${plain}"
    ln -s ${install_path}${python3_file}/bin/pip3  /usr/bin/pip3
    ln -s ${install_path}${python3_file}/bin/python3 /usr/bin/python3
    echo "PATH=${install_path}${python3_file}/bin/:\$PATH " >> /etc/profile
    echo "PYTHONPATH=\$PYTHONPATH:${install_path}${python3_file}/lib/python3/" >> /etc/profile
    source /etc/profile
    if python3  --version &> /dev/null; then 
        echo -e "[${green}Success${plain}] ${python3_file} 安装完成."
    else
        echo -e "[${red}失败${plain}] ${python3_file} 安装失败."
        exit 1
    fi

}

install_finish(){
    rm -fr ${cur_dir}/${python3_file}
    rm -fr ${cur_dir}/${python3_file}.tar.xz
    version=$( python3 --version )
    echo -e "[${green}信息${plain}] Python 版本: ${version}"
    echo -e "你可以输入 \"python3\" 以进入 ${python3_file} 也可以输入 \"pip3\" 来管理你的 python3 包."

}

install_python(){
    clear
    echo "---------------------------------------"
    echo " 自动安装 Python3"
    echo "                                       "
    echo " 系统支持:  CentOS/REHL 6+,"
    echo "  Debian(未测试)"
    echo "--------------  系统信息  --------------"
    echo " 用户    : $USER   主机: $HOSTNAME" 
    echo " 系统     : `get_opsy`"
    echo " Arch   : `uname -m`"
    echo " 内核 : `uname -r`"
    echo "--------------------------------------" 
    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

    depends_install
    install_start
    install_finish
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
        rm -fr ${install_path}${python3_file}
        rm -f /usr/bin/python3
        rm -f /usr/bin/pip3

        echo -e "[${green}信息${plain}] ${python3_file}$ 成功卸载"
        echo -e "[${green}信息${plain}] ${red}一些在 /etc/profile 无法删除 ${plain}"
    else
        echo
        echo -e "[${green}信息${plain}] ${python3_file}$ 卸载已被取消 ..."
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
        echo "输入错误! [${action}]"
        echo "使用方法: `basename $0` [install|uninstall]"
        ;;
esac
