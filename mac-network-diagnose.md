# macOS 重启后无法访问 Google — 排查与修复手册

## 一、背景
- 家里路由器已刷梅林固件 + Clash 节点 → 其他设备访问外网正常。  
- Mac 重启后无法访问 Google。  
- 打开 Clash 客户端后可访问，关掉 Clash 仍可短时间访问。  
- 可能原因：**DNS 污染 / DNS 缓存 / 系统代理 / 路由表刷新不及时**。

---

## 二、开机后操作步骤

### 1. 检查 DNS 解析
```bash
dig +short www.google.com
```
- 若返回正常 Google IP → DNS 正常。  
- 若为空或异常 → 可能是 DNS 污染。  

---

### 2. 查看当前 DNS 设置
```bash
networksetup -listallnetworkservices
networksetup -getdnsservers "Wi-Fi"
scutil --dns
```
- 检查是否在用 ISP 的 DNS。  
- 如果是路由器 DNS 或公共 DNS (1.1.1.1 / 8.8.8.8)，理论上应正常。  

---

### 3. 清理 DNS 缓存
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```
然后再测试：
```bash
dig +short www.google.com
```

---

### 4. 启动 Clash 客户端对比
```bash
dig +short www.google.com
ifconfig | grep -E "utun|tun|tap" -A2
netstat -rn | grep default
scutil --proxy
```
- 检查 Clash 是否改动了路由/代理/DNS。  

---

### 5. 关闭 Clash 后再次验证
```bash
dig +short www.google.com
```
- 如果还能解析，说明 DNS 缓存保存了结果。  
- 如果立刻失效，说明必须依赖 Clash 来设置正确路由/代理。  

---

## 三、临时解决办法

### 指定公共 DNS
```bash
sudo networksetup -setdnsservers "Wi-Fi" 1.1.1.1 8.8.8.8
```

恢复 DHCP 默认 DNS：
```bash
sudo networksetup -setdnsservers "Wi-Fi" Empty
```

---

## 四、推荐永久方案
1. 在 **路由器 DHCP** 里设置 DNS 为 `1.1.1.1` / `8.8.8.8`，让所有设备自动获取。  
2. 或在 **macOS 系统设置 → 网络 → Wi-Fi → 高级 → DNS** 手动指定。  

---

## 五、一键修复脚本

保存为 `fix-net.sh`：
```bash
#!/bin/bash
SERVICE="Wi-Fi"

echo "Flush DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
sleep 1

echo "Renew DHCP for $SERVICE ..."
sudo networksetup -renewdhcp "$SERVICE"
sleep 1

echo "Reset DNS to DHCP-assigned (Empty) ..."
sudo networksetup -setdnsservers "$SERVICE" Empty

echo "Done. Test with: dig +short www.google.com"
```

使用方法：
```bash
chmod +x fix-net.sh
./fix-net.sh
```

（如果你想强制使用公共 DNS，把 `-setdnsservers "$SERVICE" Empty` 改成 `-setdnsservers "$SERVICE" 1.1.1.1 8.8.8.8`）

---

## 六、需要进一步分析时
收集以下命令结果：
```bash
dig +short www.google.com
networksetup -getdnsservers "Wi-Fi"
scutil --dns
netstat -rn | grep default
ifconfig | grep -E "utun|tun|tap" -A2
scutil --proxy
```
