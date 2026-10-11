#!/system/bin/sh
# 一键配置手机为 [MTP + ADB + HID键盘] 复合设备
# 用法: adb shell "sh /data/local/tmp/setup-gadget.sh"
# 或手机 Termux: su; sh /sdcard/setup-gadget.sh

G=/config/usb_gadget/g1
KB=$G/functions/hid.keyboard

echo "=== 配置 HID 键盘 gadget ==="

if [ ! -d "$G" ]; then
  echo "[✗] $G 不存在"
  exit 1
fi

# 1. 创建 HID function（若不存在）
if [ ! -d "$KB" ]; then
  mkdir -p "$KB"
  echo 1 > "$KB/protocol"
  echo 1 > "$KB/subclass"
  echo 8 > "$KB/report_length"
  printf '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' > "$KB/report_desc"
  echo "[+] HID function 已创建"
else
  echo "[=] HID function 已存在"
fi

# 2. 链接进 config（若未链接）
if [ ! -e "$G/configs/b.1/function2" ]; then
  ln -s "$KB" "$G/configs/b.1/function2" 2>/dev/null && echo "[+] 已链接到 config" || echo "[=] 链接已存在或失败"
else
  echo "[=] 已链接"
fi

# 3. 重新枚举
echo "[*] 重新枚举 USB..."
echo "" > $G/UDC
sleep 1
echo "a600000.dwc3" > $G/UDC
sleep 1

# 4. 验证
if [ -e /dev/hidg0 ]; then
  echo "[✓] /dev/hidg0 存在，HID 键盘就绪"
  ls -la /dev/hidg0
else
  echo "[✗] /dev/hidg0 不存在"
fi
echo "UDC: $(cat $G/UDC)"
