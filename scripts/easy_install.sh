#!/bin/bash

# اسکریپت نصب آسان و مدیریت کاربران QUIC VPN
# اسکریپت باید با دسترسی root اجرا شود

# تنظیم رنگ‌های خروجی
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # بدون رنگ

# متغیرهای پیش‌فرض
SERVER_CONFIG_DIR="/etc/quicvpn"
SERVER_CONFIG_FILE="${SERVER_CONFIG_DIR}/server_config.json"
USERS_FILE="${SERVER_CONFIG_DIR}/users.json"
CLIENTS_DIR="${SERVER_CONFIG_DIR}/clients"
SERVER_KEY="${SERVER_CONFIG_DIR}/server.key"
SERVER_CERT="${SERVER_CONFIG_DIR}/server.crt"
QUICVPN_SERVICE="quicvpn-server.service"
DEFAULT_PORT="4433"
DEFAULT_IP_POOL="10.8.0.0/24"
SERVER_BIN="/usr/local/bin/quicvpn-server"
VERSION="1.0.0"

# بررسی اجرای با دسترسی root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}این اسکریپت باید با دسترسی root اجرا شود.${NC}"
        exit 1
    fi
}

# چاپ بنر
print_banner() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}     نصب آسان و مدیریت QUIC VPN      ${NC}"
    echo -e "${BLUE}        نسخه: ${VERSION}              ${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

# نمایش منوی اصلی
show_menu() {
    echo -e "${YELLOW}لطفا یکی از گزینه‌های زیر را انتخاب کنید:${NC}"
    echo "1) نصب سرور QUIC VPN"
    echo "2) مدیریت کاربران"
    echo "3) مدیریت سرور"
    echo "4) مشاهده وضعیت"
    echo "5) خروج"
    echo ""
    read -p "لطفا گزینه مورد نظر را وارد کنید [1-5]: " choice
    
    case $choice in
        1) install_server ;;
        2) user_management_menu ;;
        3) server_management_menu ;;
        4) show_status ;;
        5) exit 0 ;;
        *) echo -e "${RED}گزینه نامعتبر!${NC}" && show_menu ;;
    esac
}

# منوی مدیریت کاربران
user_management_menu() {
    clear
    print_banner
    echo -e "${YELLOW}منوی مدیریت کاربران:${NC}"
    echo "1) افزودن کاربر جدید"
    echo "2) حذف کاربر"
    echo "3) نمایش لیست کاربران"
    echo "4) تولید فایل پیکربندی کاربر"
    echo "5) بازگشت به منوی اصلی"
    echo ""
    read -p "لطفا گزینه مورد نظر را وارد کنید [1-5]: " choice
    
    case $choice in
        1) add_user ;;
        2) remove_user ;;
        3) list_users ;;
        4) generate_client_config ;;
        5) clear && print_banner && show_menu ;;
        *) echo -e "${RED}گزینه نامعتبر!${NC}" && user_management_menu ;;
    esac
}

# منوی مدیریت سرور
server_management_menu() {
    clear
    print_banner
    echo -e "${YELLOW}منوی مدیریت سرور:${NC}"
    echo "1) شروع سرور"
    echo "2) توقف سرور"
    echo "3) راه‌اندازی مجدد سرور"
    echo "4) نمایش لاگ سرور"
    echo "5) بازگشت به منوی اصلی"
    echo ""
    read -p "لطفا گزینه مورد نظر را وارد کنید [1-5]: " choice
    
    case $choice in
        1) start_server ;;
        2) stop_server ;;
        3) restart_server ;;
        4) show_logs ;;
        5) clear && print_banner && show_menu ;;
        *) echo -e "${RED}گزینه نامعتبر!${NC}" && server_management_menu ;;
    esac
}

# نصب بسته‌های مورد نیاز
install_dependencies() {
    echo -e "${BLUE}در حال نصب بسته‌های مورد نیاز...${NC}"
    
    # تشخیص نوع توزیع
    if [[ -f /etc/debian_version ]]; then
        apt update
        apt install -y curl wget tar jq openssl git build-essential
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y curl wget tar jq openssl git gcc make
    else
        echo -e "${RED}توزیع لینوکس شما پشتیبانی نمی‌شود.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}بسته‌های مورد نیاز با موفقیت نصب شدند.${NC}"
}

# دانلود و نصب باینری QUIC VPN
download_and_install_binary() {
    echo -e "${BLUE}در حال دانلود و نصب QUIC VPN...${NC}"
    
    # دانلود از GitHub
    echo -e "${YELLOW}دانلود از GitHub: https://github.com/Echo9009/Echo.git${NC}"
    
    # ایجاد دایرکتوری موقت
    TMP_DIR=$(mktemp -d)
    echo -e "دایرکتوری موقت: ${TMP_DIR}"
    
    # کلون کردن مخزن
    git clone https://github.com/Echo9009/Echo.git "${TMP_DIR}/quicvpn"
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}خطا در دانلود کد منبع. لطفاً اتصال اینترنت خود را بررسی کنید.${NC}"
        exit 1
    fi
    
    # ورود به دایرکتوری پروژه
    cd "${TMP_DIR}/quicvpn"
    
    # ساخت پروژه (اگر Rust است)
    echo -e "${BLUE}در حال ساخت پروژه...${NC}"
    
    # بررسی وجود فایل Cargo.toml برای پروژه‌های Rust
    if [[ -f "Cargo.toml" ]]; then
        # نصب Rust اگر نصب نشده باشد
        if ! command -v cargo &> /dev/null; then
            echo -e "${YELLOW}Rust یافت نشد. در حال نصب Rust...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
        
        # ساخت در حالت انتشار
        cargo build --release
        
        # کپی باینری سرور به مسیر نصب
        if [[ -f "target/release/quicvpn-server" ]]; then
            cp "target/release/quicvpn-server" "${SERVER_BIN}"
        elif [[ -f "target/release/server" ]]; then
            cp "target/release/server" "${SERVER_BIN}"
        else
            echo -e "${RED}فایل باینری سرور یافت نشد. لطفاً مطمئن شوید که پروژه به درستی ساخته شده است.${NC}"
            exit 1
        fi
    else
        # اگر پروژه Rust نیست، فرض می‌کنیم که باینری آماده دارد
        echo -e "${YELLOW}فایل Cargo.toml یافت نشد. تلاش برای یافتن باینری آماده...${NC}"
        
        # جستجوی باینری در دایرکتوری‌های مختلف
        FOUND_BIN=$(find . -type f -name "quicvpn-server" -o -name "server" | head -n 1)
        
        if [[ -n "${FOUND_BIN}" ]]; then
            cp "${FOUND_BIN}" "${SERVER_BIN}"
        else
            echo -e "${RED}باینری سرور در مخزن یافت نشد.${NC}"
            exit 1
        fi
    fi
    
    # اعطای مجوز اجرا به باینری
    chmod +x "${SERVER_BIN}"
    
    # پاکسازی
    cd -
    rm -rf "${TMP_DIR}"
    
    # ایجاد دایرکتوری نصب
    mkdir -p ${SERVER_CONFIG_DIR}
    mkdir -p ${CLIENTS_DIR}
    
    # نصب سرویس systemd
    cat > /etc/systemd/system/${QUICVPN_SERVICE} << EOF
[Unit]
Description=QUIC VPN Server
After=network.target

[Service]
ExecStart=${SERVER_BIN} --config ${SERVER_CONFIG_FILE}
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    
    echo -e "${GREEN}QUIC VPN با موفقیت نصب شد.${NC}"
}

# ایجاد گواهینامه TLS خودامضا برای سرور
generate_certificate() {
    echo -e "${BLUE}در حال ایجاد گواهینامه TLS...${NC}"
    
    # دریافت IP یا دامنه سرور
    read -p "نام دامنه یا آدرس IP سرور را وارد کنید: " server_domain
    
    # ایجاد کلید خصوصی و گواهینامه
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
        -keyout ${SERVER_KEY} -out ${SERVER_CERT} \
        -subj "/CN=${server_domain}" \
        -addext "subjectAltName=DNS:${server_domain},IP:${server_domain}"
    
    # تنظیم مجوزهای فایل
    chmod 600 ${SERVER_KEY}
    chmod 644 ${SERVER_CERT}
    
    echo -e "${GREEN}گواهینامه TLS با موفقیت ایجاد شد.${NC}"
}

# پیکربندی اولیه سرور
configure_server() {
    echo -e "${BLUE}در حال پیکربندی سرور...${NC}"
    
    # دریافت پارامترهای پیکربندی
    read -p "پورت سرور را وارد کنید [پیش‌فرض: ${DEFAULT_PORT}]: " server_port
    server_port=${server_port:-${DEFAULT_PORT}}
    
    read -p "محدوده آدرس IP داخلی را وارد کنید [پیش‌فرض: ${DEFAULT_IP_POOL}]: " ip_pool
    ip_pool=${ip_pool:-${DEFAULT_IP_POOL}}
    
    # ایجاد فایل پیکربندی سرور
    cat > ${SERVER_CONFIG_FILE} << EOF
{
    "listen_addr": "0.0.0.0:${server_port}",
    "cert_path": "${SERVER_CERT}",
    "key_path": "${SERVER_KEY}",
    "users_file": "${USERS_FILE}",
    "ip_pool": "${ip_pool}",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "keep_alive": 5,
    "enable_game_optimization": true,
    "log_level": "info",
    "log_file": "/var/log/quicvpn.log"
}
EOF

    # ایجاد فایل کاربران خالی
    echo '{"users": []}' > ${USERS_FILE}
    
    # تنظیم مجوزهای فایل
    chmod 600 ${SERVER_CONFIG_FILE} ${USERS_FILE}
    
    echo -e "${GREEN}پیکربندی سرور با موفقیت انجام شد.${NC}"
}

# فعال‌سازی IP Forwarding
enable_ip_forwarding() {
    echo -e "${BLUE}در حال فعال‌سازی IP Forwarding...${NC}"
    
    # فعال‌سازی IP Forwarding
    echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-quicvpn.conf
    sysctl -p /etc/sysctl.d/99-quicvpn.conf
    
    echo -e "${GREEN}IP Forwarding با موفقیت فعال شد.${NC}"
}

# تنظیم قوانین iptables
setup_firewall() {
    echo -e "${BLUE}در حال تنظیم فایروال...${NC}"
    
    # خواندن پورت از فایل پیکربندی
    local port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2)
    local ip_pool=$(jq -r '.ip_pool' ${SERVER_CONFIG_FILE})
    
    # اضافه کردن قوانین iptables
    iptables -A INPUT -p udp --dport ${port} -j ACCEPT
    iptables -A FORWARD -s ${ip_pool} -j ACCEPT
    iptables -A FORWARD -d ${ip_pool} -j ACCEPT
    iptables -t nat -A POSTROUTING -s ${ip_pool} -o eth0 -j MASQUERADE
    
    # ذخیره قوانین iptables
    if [[ -f /etc/debian_version ]]; then
        apt install -y iptables-persistent
        netfilter-persistent save
    elif [[ -f /etc/redhat-release ]]; then
        echo "iptables-save > /etc/sysconfig/iptables" > /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
        iptables-save > /etc/sysconfig/iptables
    fi
    
    echo -e "${GREEN}تنظیمات فایروال با موفقیت انجام شد.${NC}"
}

# نصب سرور QUIC VPN
install_server() {
    clear
    print_banner
    
    echo -e "${YELLOW}در حال نصب سرور QUIC VPN...${NC}"
    
    # بررسی اگر قبلاً نصب شده است
    if [[ -f ${SERVER_CONFIG_FILE} ]]; then
        read -p "به نظر می‌رسد QUIC VPN قبلاً نصب شده است. آیا می‌خواهید مجدداً نصب کنید؟ (y/n): " reinstall
        if [[ ${reinstall} != "y" && ${reinstall} != "Y" ]]; then
            echo -e "${YELLOW}نصب لغو شد.${NC}"
            show_menu
            return
        fi
    fi
    
    # مراحل نصب
    check_root
    install_dependencies
    download_and_install_binary
    generate_certificate
    configure_server
    enable_ip_forwarding
    setup_firewall
    
    # فعال‌سازی و شروع سرویس
    systemctl enable ${QUICVPN_SERVICE}
    systemctl start ${QUICVPN_SERVICE}
    
    echo -e "${GREEN}نصب سرور QUIC VPN با موفقیت انجام شد.${NC}"
    echo -e "${YELLOW}اکنون می‌توانید کاربران را اضافه کنید و فایل‌های پیکربندی کلاینت را تولید کنید.${NC}"
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    clear
    print_banner
    show_menu
}

# افزودن کاربر جدید
add_user() {
    clear
    print_banner
    
    echo -e "${YELLOW}افزودن کاربر جدید:${NC}"
    
    # بررسی وجود فایل کاربران
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}فایل کاربران یافت نشد. لطفاً ابتدا سرور را نصب کنید.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # دریافت اطلاعات کاربر
    read -p "نام کاربری: " username
    
    # بررسی تکراری بودن نام کاربری
    if jq -e --arg user "${username}" '.users[] | select(.username == $user)' ${USERS_FILE} > /dev/null; then
        echo -e "${RED}این نام کاربری قبلاً وجود دارد.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # تولید رمز عبور تصادفی
    password=$(openssl rand -hex 8)
    
    # تولید UUID برای کاربر
    user_id=$(cat /proc/sys/kernel/random/uuid)
    
    # افزودن کاربر به فایل کاربران
    jq --arg username "${username}" \
       --arg password "${password}" \
       --arg user_id "${user_id}" \
       '.users += [{"username": $username, "password": $password, "user_id": $user_id, "enabled": true}]' ${USERS_FILE} > ${USERS_FILE}.tmp
    
    mv ${USERS_FILE}.tmp ${USERS_FILE}
    
    # اعمال تغییرات
    restart_server
    
    echo -e "${GREEN}کاربر '${username}' با موفقیت اضافه شد.${NC}"
    echo -e "${YELLOW}نام کاربری: ${username}${NC}"
    echo -e "${YELLOW}رمز عبور: ${password}${NC}"
    
    # تولید فایل پیکربندی کلاینت
    generate_config_for_user "${username}" "${password}"
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    user_management_menu
}

# حذف کاربر
remove_user() {
    clear
    print_banner
    
    echo -e "${YELLOW}حذف کاربر:${NC}"
    
    # بررسی وجود فایل کاربران
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}فایل کاربران یافت نشد. لطفاً ابتدا سرور را نصب کنید.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # نمایش لیست کاربران
    list_users_simple
    
    # دریافت نام کاربری برای حذف
    read -p "نام کاربری را برای حذف وارد کنید: " username
    
    # بررسی وجود کاربر
    if ! jq -e --arg user "${username}" '.users[] | select(.username == $user)' ${USERS_FILE} > /dev/null; then
        echo -e "${RED}کاربر مورد نظر یافت نشد.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # حذف کاربر از فایل کاربران
    jq --arg user "${username}" '.users = [.users[] | select(.username != $user)]' ${USERS_FILE} > ${USERS_FILE}.tmp
    
    mv ${USERS_FILE}.tmp ${USERS_FILE}
    
    # حذف فایل پیکربندی کاربر اگر وجود دارد
    if [[ -f "${CLIENTS_DIR}/${username}.json" ]]; then
        rm "${CLIENTS_DIR}/${username}.json"
    fi
    
    # اعمال تغییرات
    restart_server
    
    echo -e "${GREEN}کاربر '${username}' با موفقیت حذف شد.${NC}"
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    user_management_menu
}

# نمایش لیست کاربران ساده
list_users_simple() {
    echo "لیست کاربران موجود:"
    echo "--------------------------"
    
    if [[ ! -f ${USERS_FILE} ]]; then
        echo "هیچ کاربری یافت نشد."
        return
    fi
    
    jq -r '.users[] | "\(.username) (\(if .enabled then "فعال" else "غیرفعال" end))"' ${USERS_FILE}
    echo "--------------------------"
}

# نمایش لیست کاربران
list_users() {
    clear
    print_banner
    
    echo -e "${YELLOW}لیست کاربران:${NC}"
    
    # بررسی وجود فایل کاربران
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}فایل کاربران یافت نشد. لطفاً ابتدا سرور را نصب کنید.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # نمایش تعداد کاربران
    user_count=$(jq '.users | length' ${USERS_FILE})
    echo -e "${GREEN}تعداد کاربران: ${user_count}${NC}"
    
    # نمایش جزئیات کاربران
    echo -e "\n${BLUE}اطلاعات کاربران:${NC}"
    jq -r '.users[] | "نام کاربری: \(.username)\nوضعیت: \(if .enabled then "فعال" else "غیرفعال" end)\nشناسه: \(.user_id)\n-------------------"' ${USERS_FILE}
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    user_management_menu
}

# تولید فایل پیکربندی برای یک کاربر
generate_config_for_user() {
    local username="$1"
    local password="$2"
    
    # دریافت اطلاعات سرور
    local server_ip=$(curl -s ifconfig.me)
    local server_port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2)
    
    # ایجاد دایرکتوری برای فایل‌های پیکربندی اگر وجود ندارد
    mkdir -p ${CLIENTS_DIR}
    
    # ایجاد فایل پیکربندی کلاینت
    cat > "${CLIENTS_DIR}/${username}.json" << EOF
{
    "server_addr": "${server_ip}:${server_port}",
    "username": "${username}",
    "password": "${password}",
    "allow_insecure": true,
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "auto_reconnect": true,
    "gaming_optimization": true,
    "log_level": "info"
}
EOF
    
    echo -e "${GREEN}فایل پیکربندی کلاینت برای کاربر '${username}' در مسیر ${CLIENTS_DIR}/${username}.json ایجاد شد.${NC}"
    echo -e "${YELLOW}دستور زیر را برای اتصال استفاده کنید:${NC}"
    echo -e "${BLUE}quicvpn-client --config ${username}.json${NC}"
}

# تولید فایل پیکربندی کلاینت
generate_client_config() {
    clear
    print_banner
    
    echo -e "${YELLOW}تولید فایل پیکربندی کلاینت:${NC}"
    
    # بررسی وجود فایل کاربران
    if [[ ! -f ${USERS_FILE} ]]; then
        echo -e "${RED}فایل کاربران یافت نشد. لطفاً ابتدا سرور را نصب کنید.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # نمایش لیست کاربران
    list_users_simple
    
    # دریافت نام کاربری
    read -p "نام کاربری را برای تولید فایل پیکربندی وارد کنید: " username
    
    # بررسی وجود کاربر
    if ! jq -e --arg user "${username}" '.users[] | select(.username == $user)' ${USERS_FILE} > /dev/null; then
        echo -e "${RED}کاربر مورد نظر یافت نشد.${NC}"
        read -p "فشار دهید برای ادامه..." -n1 -s
        user_management_menu
        return
    fi
    
    # دریافت رمز عبور کاربر
    password=$(jq -r --arg user "${username}" '.users[] | select(.username == $user) | .password' ${USERS_FILE})
    
    # تولید فایل پیکربندی
    generate_config_for_user "${username}" "${password}"
    
    # نمایش مسیر دانلود
    echo -e "${YELLOW}مسیر فایل پیکربندی: ${CLIENTS_DIR}/${username}.json${NC}"
    echo -e "${YELLOW}می‌توانید این فایل را به کاربر ارسال کنید.${NC}"
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    user_management_menu
}

# شروع سرور
start_server() {
    echo -e "${BLUE}در حال شروع سرور QUIC VPN...${NC}"
    systemctl start ${QUICVPN_SERVICE}
    sleep 2
    
    if systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "${GREEN}سرور QUIC VPN با موفقیت شروع شد.${NC}"
    else
        echo -e "${RED}شروع سرور QUIC VPN با خطا مواجه شد. لطفاً لاگ‌ها را بررسی کنید.${NC}"
    fi
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    server_management_menu
}

# توقف سرور
stop_server() {
    echo -e "${BLUE}در حال توقف سرور QUIC VPN...${NC}"
    systemctl stop ${QUICVPN_SERVICE}
    sleep 2
    
    if ! systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "${GREEN}سرور QUIC VPN با موفقیت متوقف شد.${NC}"
    else
        echo -e "${RED}توقف سرور QUIC VPN با خطا مواجه شد.${NC}"
    fi
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    server_management_menu
}

# راه‌اندازی مجدد سرور
restart_server() {
    echo -e "${BLUE}در حال راه‌اندازی مجدد سرور QUIC VPN...${NC}"
    systemctl restart ${QUICVPN_SERVICE}
    sleep 2
    
    if systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "${GREEN}سرور QUIC VPN با موفقیت راه‌اندازی مجدد شد.${NC}"
    else
        echo -e "${RED}راه‌اندازی مجدد سرور QUIC VPN با خطا مواجه شد. لطفاً لاگ‌ها را بررسی کنید.${NC}"
    fi
}

# نمایش لاگ سرور
show_logs() {
    echo -e "${BLUE}نمایش لاگ‌های سرور QUIC VPN:${NC}"
    journalctl -u ${QUICVPN_SERVICE} -n 50 --no-pager
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    server_management_menu
}

# نمایش وضعیت
show_status() {
    clear
    print_banner
    
    echo -e "${YELLOW}وضعیت سرور QUIC VPN:${NC}"
    
    # نمایش وضعیت سرویس
    echo -e "${BLUE}وضعیت سرویس:${NC}"
    systemctl status ${QUICVPN_SERVICE} --no-pager | head -n 3
    
    # نمایش آمار اتصالات
    if systemctl is-active --quiet ${QUICVPN_SERVICE}; then
        echo -e "\n${BLUE}آمار اتصالات:${NC}"
        # در اینجا می‌توان از دستورات سفارشی برای نمایش آمار استفاده کرد
        # برای نمونه، فرض می‌کنیم که سرور دارای یک API برای دریافت آمار است
        if [[ -f ${USERS_FILE} ]]; then
            user_count=$(jq '.users | length' ${USERS_FILE})
            echo -e "تعداد کاربران: ${user_count}"
        fi
    fi
    
    # نمایش اطلاعات شبکه
    echo -e "\n${BLUE}اطلاعات شبکه:${NC}"
    # نمایش آدرس IP خارجی سرور
    server_ip=$(curl -s ifconfig.me)
    server_port=$(jq -r '.listen_addr' ${SERVER_CONFIG_FILE} | cut -d':' -f2 2>/dev/null || echo "${DEFAULT_PORT}")
    echo -e "آدرس IP سرور: ${server_ip}"
    echo -e "پورت سرور: ${server_port}"
    
    read -p "فشار دهید برای ادامه..." -n1 -s
    clear
    print_banner
    show_menu
}

# اجرای اصلی
check_root
clear
print_banner
show_menu 