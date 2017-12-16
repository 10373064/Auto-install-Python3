# Auto install Python3
Auto install Python3

Only for centos 6+, debian (**untest**) **now**
## Quick start
```bash
wget --no-check-certificate -O python3.sh https://git.io/vbojf && chmod +x python3.sh && bash python3.sh
```

```bash
wget --no-check-certificate -O python3.sh https://raw.githubusercontent.com/evrmji/Auto-install-Python3/master/python3.sh && chmod +x python3.sh && bash python3.sh
```
Less output
```bash
wget --no-check-certificate -O py3install.sh https://git.io/vbKfE && chmod +x py3install.sh && bash py3install.sh
```
```bash
wget --no-check-certificate -O py3install.sh https://raw.githubusercontent.com/evrmji/Auto-install-Python3/master/py3install.sh && chmod +x py3install.sh && bash py3install.sh
```

## Usage
```bash
yum install wget screen
screen -S pyinstall
wget --no-check-certificate -O python3.sh https://raw.githubusercontent.com/evrmji/Auto-install-Python3/master/python3.sh
chmod +x python3.sh
./python3.sh 2>&1 | tee python3.log
# If you lost the connecting of server you can use `screen -r pyinstall`. 
```
