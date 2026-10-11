#!/system/bin/sh
# ============================================================
# HID 键盘发送脚本 —— 直接在手机上运行（Termux 或 adb shell）
# 前提：手机已 root，且 HID gadget 已配置好（/dev/hidg0 存在）
#
# 用法：
#   sh hid-phone.sh space        # 按空格
#   sh hid-phone.sh tab enter    # 按 Tab 再 Enter
#   sh hid-phone.sh a b c        # 输入 abc
#   sh hid-phone.sh hello        # 输入 hello
# ============================================================

HID=/dev/hidg0

# 若 /dev/hidg0 不存在，尝试自动配置
if [ ! -e "$HID" ]; then
  echo "[!] $HID 不存在，尝试自动配置 HID gadget..."
  if [ "$(id -u)" != "0" ]; then
    echo "[!] 需要 root，请用 su 或先 adb root"
  fi
fi

# ---- 8 字节键盘报告辅助 ----
# press <mod> <key> : 按下再释放
press() {
  printf "\\x$(printf '%02x' "$1")\\x00\\x$(printf '%02x' "$2")\\x00\\x00\\x00\\x00\\x00" > "$HID"
  sleep 0.06
  printf '\x00\x00\x00\x00\x00\x00\x00\x00' > "$HID"
  sleep 0.06
}

# ---- 键名 → 键码 ----
# 修饰键
MOD_CTRL=1; MOD_SHIFT=2; MOD_ALT=4

# 发送一个键名
send_key() {
  case "$1" in
    space)  press 0 44 ;;   # 0x2C
    enter)  press 0 40 ;;   # 0x28
    tab)    press 0 43 ;;   # 0x2B
    esc)    press 0 41 ;;   # 0x29
    back|backspace) press 0 42 ;;  # 0x2A
    up)     press 0 82 ;;   # 0x52
    down)   press 0 81 ;;   # 0x51
    left)   press 0 80 ;;   # 0x50
    right)  press 0 79 ;;   # 0x4F
    shift_tab|shtab) press 2 43 ;;  # Shift+Tab
    # 数字
    1) press 0 30 ;; 2) press 0 31 ;; 3) press 0 32 ;; 4) press 0 33 ;; 5) press 0 34 ;;
    6) press 0 35 ;; 7) press 0 36 ;; 8) press 0 37 ;; 9) press 0 38 ;; 0) press 0 39 ;;
    # 字母 a-z = 0x04 + (letter - 'a')
    a) press 0 4 ;;  b) press 0 5 ;;  c) press 0 6 ;;  d) press 0 7 ;;  e) press 0 8 ;;
    f) press 0 9 ;;  g) press 0 10 ;; h) press 0 11 ;; i) press 0 12 ;; j) press 0 13 ;;
    k) press 0 14 ;; l) press 0 15 ;; m) press 0 16 ;; n) press 0 17 ;; o) press 0 18 ;;
    p) press 0 19 ;; q) press 0 20 ;; r) press 0 21 ;; s) press 0 22 ;; t) press 0 23 ;;
    u) press 0 24 ;; v) press 0 25 ;; w) press 0 26 ;; x) press 0 27 ;; y) press 0 28 ;;
    z) press 0 29 ;;
    # 符号
    -) press 0 45 ;; =) press 0 46 ;; .) press 0 55 ;; ,) press 0 54 ;; /) press 0 56 ;;
    *) echo "未知键: $1"; return 1 ;;
  esac
}

# ---- 逐字符输入一个字符串 ----
type_str() {
  local s="$1" i c
  for (( i=0; i<${#s}; i++ )); do
    c="${s:$i:1}"
    send_key "$c"
  done
}

# ---- 主逻辑 ----
if [ $# -eq 0 ]; then
  echo "用法:"
  echo "  sh $0 <键...>      逐个发送按键 (space/enter/tab/up/down/left/right/esc/a-z/0-9)"
  echo "  sh $0 hello        逐字符输入字符串"
  echo ""
  echo "示例:"
  echo "  sh $0 a b c        # 输入 abc"
  echo "  sh $0 tab tab enter  # Tab Tab Enter"
  echo "  sh $0 hello        # 输入 hello"
  exit 0
fi

if [ ! -e "$HID" ]; then
  echo "[✗] $HID 不存在！HID gadget 未配置。先在电脑上配置，或看 docs/developer-mode.md"
  exit 1
fi

# 单参数且是多字符 → 当作字符串逐字符输入
if [ $# -eq 1 ] && [ ${#1} -gt 1 ] && [ "$1" != "space" ] && [ "$1" != "enter" ] && [ "$1" != "tab" ] && [ "$1" != "shift_tab" ]; then
  case "$1" in
    space|enter|tab|esc|backspace|up|down|left|right|shtab) send_key "$1" ;;
    *) echo "输入字符串: $1"; type_str "$1" ;;
  esac
else
  for k in "$@"; do
    send_key "$k"
    echo "→ $k"
  done
fi

echo "完成"
