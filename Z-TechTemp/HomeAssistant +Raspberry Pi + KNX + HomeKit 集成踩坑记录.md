asus 路由器 + RaspberryPi+ Mac
## Homeassistant 烧录部分
##### 1. 下载树莓派烧录软件，选择对应的系统。如果你当前用的是 macos 就选择 macos 版本。 https://www.home-assistant.io/installation/raspberrypi ![[Pasted image 20250730170217.png|575]]
##### 2. 烧录 Homeassistant至 sd 卡。
1. 选择对应的树莓派版本
 ![[Pasted image 20250730165216.png|275]]
2. 操作系统
	1. Other Specific-purpose OS➡️ HomeAssistants & HomeAutomation
 ![[Pasted image 20250730170647.png|200]]
 ![[Pasted image 20250730170736.png|375]]
 ![[Pasted image 20250730170949.png|250]]
3. 储存设备：准备好的 SD 卡
4. 点击下一步烧录
#### 这里碰到的坑
 1. 烧录过慢，镜像下载失败（超过 5 分钟或者进度条几乎龟速），可以直接选择先将镜像下载至本地，（ https://www.home-assistant.io/installation/raspberrypi#downloading-the-home-assistant-image） 然后直接选择这个镜像烧录至 sd 卡
![[Pasted image 20250730171541.png|650]]

2. 这里安装时可以自定义配置。 ![[Pasted image 20250730172010.png|375]]网上建议可以将 ssh打开及 wlan 地址配好，或许第一遍可以不插网线。但是我第一遍配置完 homeassistant 一直没有初始化成功，所以后面重新烧录完，还是没有选择自定义配置，选择直接插网线等开机。

## HomeAssistant启动配置部分
### HomeAssistant初始化
烧录完后会有提示拔下 sd 卡，这时候可以把 sd 卡插到树莓派上，接通电源以及网线等待初始化，这时候我们可以打开 http://homeassistant.local:8123/ 查看进度。初始化时 我看到日志里homeAssistant会去 github拉取core/supervisor 等相关镜像，所以如果电脑访问 github 过慢，会让初始化时间大幅度增加。这时候我前往 asus 后台打开了一下🪜，初始化基本在 20min 左右搞定。

### HomeAssistant加载项
1. 打开高级设置
	点击左下角设用户设置➡️高级设置开关打开➡️点击设置➡️系统➡️右上角开关➡️重启 HA
2. 重启完毕后点击设置➡️加载项➡️加载项商店➡️安装 Termianl & SSH（FileEditor也可以一起安装了）
	### 坑### 这里可能会碰到打开加载项商店为空的原因，可能是 dns 解析问题，所以我又去 asus 后台关闭了🪜再重新启动 HA，这时候就可以看到加载项商店了，如果安装过慢的话可以再打开一下🪜，因为也需要访问 github，可以快速搞定
3. 安装 HACS ： 打开 Terminal，输入： wget -q -O - https://install.hacs.xyz | bash -
### 安装集成
#### xiaomi home官方 集成
1. 在 hacs 里搜索xiaomi home,添加到 ha 中，会有跳转登录流程，在那之后的配置基本上和大部分一样，筛选设备入网，集成 HA （这个网上教程太多了不写了）
#### 安装 KNX 集成
1. 找到knxip 地址
	1.  在路由器后台或者相关软件（列入 fing）找到KNX 的 WLAN地址
	2. 如果没有找到的话我借助电脑 在 mac 端~
		sudo nmap -sn 192.168.1.0/24 
		可以扫出来。
	3. http://192.168.1.232/cgi-bin/login.cgi
2. 设备与服务➡️添加集成➡️搜索 KNX➡️配置 KNX 接口➡️选择 Tunneling选择Manual ➡️选择 UDP填写刚找到的 Ip 地址提交![[Pasted image 20250730175107.png|250]]
 ![[Pasted image 20250730174912.png|250]]
#### 配置 KNX的开关进入 HA
 1. 进入 knx 后台找到对应开关的地址，具体客餐厅灯带及空调的开关状态地址可以在这里找到
![[Pasted image 20250730174636.png]]
2. 打开 FileEditor 加载项，新建一个 KNX 文件夹，并在该文件夹下新建一个 yaml 文件
![[Pasted image 20250730175355.png|400]] ![[Pasted image 20250730175447.png|325]]
3. 配置对应的开关状态地址及名字![[Pasted image 20250730175518.png]]
4. 在 configuration中引入刚刚的新建的文件夹，会读取该路径的 yaml 文件，然后重启 HA![[Pasted image 20250730175557.png]]