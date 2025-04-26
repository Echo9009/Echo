# راه‌اندازی سرور

این بخش شامل راهنمای کامل راه‌اندازی سرور QUIC VPN با تمام گزینه‌های پیکربندی و مدیریتی است.

## پیکربندی سرور

### نیازمندی‌های سخت‌افزاری

برای راه‌اندازی سرور QUIC VPN با کارایی مناسب، به موارد زیر نیاز دارید:

| مورد | حداقل | توصیه شده |
|------|-------|-----------|
| CPU | 2 هسته، 2 گیگاهرتز | 4+ هسته، 3+ گیگاهرتز |
| RAM | 1 گیگابایت | 4+ گیگابایت |
| دیسک | 10 گیگابایت HDD | 20+ گیگابایت SSD |
| پهنای باند | 100 مگابیت/ثانیه | 1+ گیگابیت/ثانیه |

### فایل پیکربندی

سرور QUIC VPN از یک فایل پیکربندی JSON استفاده می‌کند. این فایل به صورت پیش‌فرض در مسیر `/etc/quicvpn/config.json` قرار دارد. ساختار این فایل به شرح زیر است:

```json
{
    "listen_addr": "0.0.0.0:4433",
    "cert_path": "/etc/quicvpn/server.crt",
    "key_path": "/etc/quicvpn/server.key",
    "users_file": "/etc/quicvpn/users.json",
    "log_level": "info",
    "ip_pool": "10.8.0.0/24",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "enable_ipv6": false,
    "game_optimization": true,
    "max_clients": 100,
    "idle_timeout": 300,
    "keep_alive": 5
}
```

#### گزینه‌های پیکربندی

| گزینه | توضیح | مقدار پیش‌فرض |
|-------|-------|---------------|
| `listen_addr` | آدرس:پورت گوش دادن سرور | `0.0.0.0:4433` |
| `cert_path` | مسیر فایل گواهینامه TLS | `/etc/quicvpn/server.crt` |
| `key_path` | مسیر فایل کلید خصوصی TLS | `/etc/quicvpn/server.key` |
| `users_file` | مسیر فایل کاربران | `/etc/quicvpn/users.json` |
| `log_level` | سطح لاگ (`error`, `warn`, `info`, `debug`, `trace`) | `info` |
| `ip_pool` | رنج IP برای تخصیص به کلاینت‌ها | `10.8.0.0/24` |
| `dns_servers` | لیست سرورهای DNS برای کلاینت‌ها | `["8.8.8.8", "1.1.1.1"]` |
| `mtu` | حداکثر اندازه بسته انتقال | `1400` |
| `enable_ipv6` | فعال‌سازی پشتیبانی از IPv6 | `false` |
| `game_optimization` | فعال‌سازی بهینه‌سازی‌های گیمینگ | `true` |
| `max_clients` | حداکثر تعداد کلاینت‌های همزمان | `100` |
| `idle_timeout` | زمان قطع اتصال غیرفعال (ثانیه) | `300` |
| `keep_alive` | فاصله پیام‌های keep-alive (ثانیه) | `5` |

### آغاز سرور

برای راه‌اندازی سرور QUIC VPN، می‌توان از دستور زیر استفاده کرد:

```bash
quicvpn-server --config /etc/quicvpn/config.json
```

#### گزینه‌های خط فرمان

| گزینه | توضیح |
|-------|-------|
| `--config <path>` | مسیر فایل پیکربندی |
| `--generate-cert` | تولید گواهینامه و کلید خودامضا |
| `--version` | نمایش نسخه برنامه |
| `--help` | نمایش راهنما |

#### راه‌اندازی خودکار با systemd

برای اطمینان از راه‌اندازی خودکار سرور پس از راه‌اندازی مجدد سیستم، می‌توان از systemd استفاده کرد. فایل سرویس systemd را در مسیر `/etc/systemd/system/quicvpn.service` با محتوای زیر ایجاد کنید:

```ini
[Unit]
Description=QUIC VPN Gaming Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/quicvpn-server --config /etc/quicvpn/config.json
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

سپس با دستورات زیر سرویس را فعال و شروع کنید:

```bash
sudo systemctl daemon-reload
sudo systemctl enable quicvpn
sudo systemctl start quicvpn
```

## مدیریت کاربران

### ساختار فایل کاربران

کاربران QUIC VPN در فایل JSON کاربران ذخیره می‌شوند. ساختار این فایل به شرح زیر است:

```json
{
    "users": [
        {
            "username": "user1",
            "password_hash": "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8",
            "enabled": true,
            "ip_address": "10.8.0.2",
            "max_connections": 3,
            "expiry_date": "2023-12-31",
            "bandwidth_limit": 1000000,
            "game_profile": "FPS"
        },
        {
            "username": "user2",
            "password_hash": "ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f",
            "enabled": true,
            "ip_address": "10.8.0.3",
            "max_connections": 1,
            "expiry_date": "2023-12-31",
            "bandwidth_limit": 2000000,
            "game_profile": "MOBA"
        }
    ]
}
```

#### فیلدهای کاربر

| فیلد | توضیح | الزامی |
|------|-------|--------|
| `username` | نام کاربری | بله |
| `password_hash` | هش SHA-256 رمز عبور | بله |
| `enabled` | فعال یا غیرفعال بودن کاربر | بله |
| `ip_address` | آدرس IP ثابت (اختیاری، اگر نباشد از ip_pool اختصاص داده می‌شود) | خیر |
| `max_connections` | حداکثر تعداد اتصال همزمان | خیر |
| `expiry_date` | تاریخ انقضای حساب (فرمت YYYY-MM-DD) | خیر |
| `bandwidth_limit` | محدودیت پهنای باند (بایت بر ثانیه) | خیر |
| `game_profile` | پروفایل بهینه‌سازی بازی (`FPS`, `MOBA`, `MMO`, `Racing`, `Default`) | خیر |

### افزودن کاربر جدید

QUIC VPN یک ابزار خط فرمان برای مدیریت کاربران دارد:

```bash
quicvpn-admin user add --username user3 --password "mySecurePassword" --max-connections 2 --game-profile "MOBA"
```

این دستور کاربر جدیدی را به فایل کاربران اضافه می‌کند. هش رمز عبور به صورت خودکار محاسبه می‌شود.

### ویرایش کاربر موجود

```bash
quicvpn-admin user edit --username user3 --max-connections 3 --enabled false
```

### حذف کاربر

```bash
quicvpn-admin user delete --username user3
```

### تغییر رمز عبور

```bash
quicvpn-admin user password --username user3 --password "newSecurePassword"
```

### نمایش لیست کاربران

```bash
quicvpn-admin user list
```

## مدیریت گواهینامه‌ها

QUIC VPN از TLS برای رمزنگاری استفاده می‌کند و نیاز به گواهینامه و کلید خصوصی دارد.

### تولید گواهینامه خودامضا

برای محیط‌های تست یا استفاده شخصی، می‌توان از گواهینامه خودامضا استفاده کرد:

```bash
# با استفاده از ابزار QUIC VPN
quicvpn-server --generate-cert

# یا با استفاده از OpenSSL
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes
```

### استفاده از گواهینامه معتبر

برای محیط‌های تولید، استفاده از گواهینامه معتبر توصیه می‌شود. می‌توان از Let's Encrypt به صورت رایگان گواهینامه معتبر دریافت کرد:

```bash
# نصب certbot
sudo apt install certbot

# دریافت گواهینامه
sudo certbot certonly --standalone -d vpn.example.com

# کپی گواهینامه‌ها به مسیر QUIC VPN
sudo cp /etc/letsencrypt/live/vpn.example.com/fullchain.pem /etc/quicvpn/server.crt
sudo cp /etc/letsencrypt/live/vpn.example.com/privkey.pem /etc/quicvpn/server.key
```

### تنظیم تمدید خودکار گواهینامه

برای تمدید خودکار گواهینامه Let's Encrypt، می‌توانید یک cron job ایجاد کنید:

```bash
sudo crontab -e
```

سپس خط زیر را اضافه کنید:

```
0 0 1 * * certbot renew --quiet && systemctl restart quicvpn
```

این دستور در اولین روز هر ماه، گواهینامه را در صورت نیاز تمدید کرده و سرویس QUIC VPN را مجدداً راه‌اندازی می‌کند.

## تنظیمات شبکه

### تنظیم فایروال

برای اطمینان از دسترسی کلاینت‌ها به سرور QUIC VPN، باید پورت UDP مورد استفاده را در فایروال باز کنید:

```bash
# برای UFW (Ubuntu)
sudo ufw allow 4433/udp
sudo ufw reload

# برای firewalld (CentOS/Fedora)
sudo firewall-cmd --permanent --add-port=4433/udp
sudo firewall-cmd --reload

# برای iptables
sudo iptables -A INPUT -p udp --dport 4433 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

### فعال‌سازی IP Forwarding

برای عملکرد صحیح VPN، باید IP Forwarding در سرور فعال باشد:

```bash
# فعال‌سازی موقت
sudo sysctl -w net.ipv4.ip_forward=1

# فعال‌سازی دائمی
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### NAT و Masquerading

برای دسترسی کلاینت‌ها به اینترنت از طریق سرور، باید NAT را تنظیم کنید:

```bash
# فرض می‌کنیم eth0 اینترفیس خارجی سرور است
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# ذخیره‌سازی دائمی قوانین iptables
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

### بهینه‌سازی MTU

برای بهینه‌سازی انتقال داده، می‌توانید MTU را تنظیم کنید:

```bash
sudo ip link set dev tun0 mtu 1400
```

این مقدار در فایل پیکربندی سرور نیز قابل تنظیم است (`mtu` در `config.json`).

## نظارت و پایش

### لاگ‌ها

لاگ‌های QUIC VPN به صورت پیش‌فرض در خروجی استاندارد و همچنین در `/var/log/quicvpn.log` ذخیره می‌شوند. برای مشاهده لاگ‌ها در زمان واقعی:

```bash
# اگر از systemd استفاده می‌کنید
sudo journalctl -u quicvpn -f

# یا مستقیماً از فایل لاگ
tail -f /var/log/quicvpn.log
```

### آمار و وضعیت

برای مشاهده وضعیت سرور و آمار اتصالات:

```bash
quicvpn-admin status
```

این دستور اطلاعاتی مانند تعداد کلاینت‌های متصل، میزان ترافیک، و وضعیت سیستم را نمایش می‌دهد.

### نظارت بر ترافیک

برای نظارت دقیق‌تر بر ترافیک، می‌توانید از ابزارهایی مانند `iftop` یا `nethogs` استفاده کنید:

```bash
# نصب ابزارها
sudo apt install iftop nethogs

# نظارت بر ترافیک اینترفیس tun0
sudo iftop -i tun0

# نظارت بر مصرف ترافیک بر اساس پروسس
sudo nethogs tun0
```

### اعلان خودکار مشکلات

می‌توانید یک اسکریپت ساده برای نظارت بر وضعیت سرور و ارسال اعلان در صورت بروز مشکل ایجاد کنید:

```bash
#!/bin/bash
# /usr/local/bin/quicvpn-monitor.sh

# بررسی فعال بودن سرویس
if ! systemctl is-active --quiet quicvpn; then
    # ارسال ایمیل در صورت غیرفعال بودن سرویس
    echo "QUIC VPN service is down on $(hostname) at $(date)" | mail -s "QUIC VPN Alert" admin@example.com
    
    # تلاش برای راه‌اندازی مجدد سرویس
    systemctl restart quicvpn
fi

# بررسی تعداد کاربران متصل
CONNECTED_USERS=$(quicvpn-admin status | grep "Connected clients" | awk '{print $3}')
if [ "$CONNECTED_USERS" -eq 0 ]; then
    echo "No users connected to QUIC VPN on $(hostname) at $(date)" | mail -s "QUIC VPN Warning" admin@example.com
fi
```

سپس این اسکریپت را در cron قرار دهید تا هر 5 دقیقه اجرا شود:

```bash
chmod +x /usr/local/bin/quicvpn-monitor.sh
(crontab -l ; echo "*/5 * * * * /usr/local/bin/quicvpn-monitor.sh") | crontab -
```

## عیب‌یابی سرور

### مشکل: سرور شروع به کار نمی‌کند

**علائم**:
- سرویس QUIC VPN شروع به کار نمی‌کند
- در لاگ‌ها پیام خطا مشاهده می‌شود

**راه حل‌ها**:
1. بررسی فایل پیکربندی:
   ```bash
   # اطمینان از صحت JSON
   jq . /etc/quicvpn/config.json
   ```

2. بررسی دسترسی‌های فایل‌ها:
   ```bash
   # بررسی دسترسی‌های فایل‌های گواهینامه و کلید
   ls -l /etc/quicvpn/server.crt /etc/quicvpn/server.key
   # اطمینان از صحیح بودن دسترسی‌ها
   sudo chmod 644 /etc/quicvpn/server.crt
   sudo chmod 600 /etc/quicvpn/server.key
   ```

3. بررسی پورت:
   ```bash
   # اطمینان از عدم استفاده پورت توسط برنامه دیگر
   sudo netstat -tulpn | grep 4433
   ```

### مشکل: کلاینت‌ها نمی‌توانند متصل شوند

**علائم**:
- کلاینت‌ها با خطای اتصال مواجه می‌شوند
- در لاگ سرور مشکلی دیده نمی‌شود

**راه حل‌ها**:
1. بررسی فایروال:
   ```bash
   # اطمینان از باز بودن پورت در فایروال
   sudo ufw status
   # یا
   sudo firewall-cmd --list-all
   ```

2. بررسی دسترسی شبکه:
   ```bash
   # از سیستم کلاینت
   telnet server-ip 4433
   # یا
   nc -vz server-ip 4433
   ```

3. بررسی تنظیمات NAT در روتر (اگر سرور پشت NAT است):
   - اطمینان از port forwarding صحیح UDP 4433

### مشکل: کلاینت‌ها متصل می‌شوند اما ترافیک عبور نمی‌کند

**علائم**:
- کلاینت‌ها متصل می‌شوند
- اما دسترسی به اینترنت یا شبکه‌های دیگر ندارند

**راه حل‌ها**:
1. بررسی IP Forwarding:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   # باید مقدار 1 باشد
   ```

2. بررسی قوانین NAT:
   ```bash
   sudo iptables -t nat -L -v
   # اطمینان از وجود قانون MASQUERADE
   ```

3. بررسی مسیریابی:
   ```bash
   ip route
   # اطمینان از صحت مسیرها
   ```

4. بررسی DNS:
   ```bash
   # اطمینان از صحت تنظیمات DNS در فایل پیکربندی
   cat /etc/quicvpn/config.json | grep dns_servers
   ```

### مشکل: عملکرد کند VPN

**علائم**:
- سرعت انتقال داده پایین است
- تأخیر بالا در بازی‌ها با وجود بهینه‌سازی گیمینگ

**راه حل‌ها**:
1. بررسی منابع سیستم:
   ```bash
   # بررسی استفاده از CPU و حافظه
   top
   
   # بررسی پهنای باند
   iftop -i eth0
   ```

2. تنظیم پارامترهای بهینه‌سازی:
   ```bash
   # ویرایش فایل پیکربندی
   sudo nano /etc/quicvpn/config.json
   
   # تنظیم MTU بهینه
   # "mtu": 1400,
   
   # فعال‌سازی بهینه‌سازی گیمینگ
   # "game_optimization": true,
   ```

3. بررسی تنظیمات شبکه سرور:
   ```bash
   # افزایش buffer size شبکه
   sudo sysctl -w net.core.rmem_max=26214400
   sudo sysctl -w net.core.wmem_max=26214400
   ```

4. بررسی محدودیت تعداد فایل‌های باز:
   ```bash
   # افزایش محدودیت
   sudo sysctl -w fs.file-max=655350
   ```

## ارتقا و بروزرسانی

### بروزرسانی نرم‌افزار

برای بروزرسانی QUIC VPN به آخرین نسخه:

```bash
# دانلود آخرین نسخه
wget https://github.com/username/quicvpn/releases/latest/download/quicvpn-server-linux.tar.gz
tar xzf quicvpn-server-linux.tar.gz
cd quicvpn-server

# پشتیبان‌گیری از فایل‌های پیکربندی
sudo cp /etc/quicvpn/config.json /etc/quicvpn/config.json.bak
sudo cp /etc/quicvpn/users.json /etc/quicvpn/users.json.bak

# نصب نسخه جدید
sudo ./update.sh

# راه‌اندازی مجدد سرویس
sudo systemctl restart quicvpn
```

### بروزرسانی گواهینامه

برای بروزرسانی گواهینامه سرور:

```bash
# بروزرسانی گواهینامه Let's Encrypt
sudo certbot renew

# کپی گواهینامه‌های جدید
sudo cp /etc/letsencrypt/live/vpn.example.com/fullchain.pem /etc/quicvpn/server.crt
sudo cp /etc/letsencrypt/live/vpn.example.com/privkey.pem /etc/quicvpn/server.key

# تنظیم دسترسی‌ها
sudo chmod 644 /etc/quicvpn/server.crt
sudo chmod 600 /etc/quicvpn/server.key

# راه‌اندازی مجدد سرویس
sudo systemctl restart quicvpn
```

### ارتقای سیستم عامل

قبل از ارتقای سیستم عامل، اطمینان حاصل کنید که سرویس QUIC VPN به درستی متوقف شده و پشتیبان‌گیری شده است:

```bash
# متوقف کردن سرویس
sudo systemctl stop quicvpn

# پشتیبان‌گیری
sudo tar -czf quicvpn-backup.tar.gz /etc/quicvpn

# انجام ارتقای سیستم عامل
sudo apt update && sudo apt upgrade

# راه‌اندازی مجدد سرویس
sudo systemctl start quicvpn
```

## مثال‌های پیکربندی

### سرور با تمرکز بر گیمینگ

```json
{
    "listen_addr": "0.0.0.0:4433",
    "cert_path": "/etc/quicvpn/server.crt",
    "key_path": "/etc/quicvpn/server.key",
    "users_file": "/etc/quicvpn/users.json",
    "log_level": "info",
    "ip_pool": "10.8.0.0/24",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "enable_ipv6": false,
    "game_optimization": true,
    "max_clients": 50,
    "idle_timeout": 300,
    "keep_alive": 2
}
```

### سرور با امنیت بالا

```json
{
    "listen_addr": "0.0.0.0:4433",
    "cert_path": "/etc/quicvpn/server.crt",
    "key_path": "/etc/quicvpn/server.key",
    "users_file": "/etc/quicvpn/users.json",
    "log_level": "warn",
    "ip_pool": "10.8.0.0/24",
    "dns_servers": ["9.9.9.9", "1.0.0.1"],
    "mtu": 1400,
    "enable_ipv6": false,
    "game_optimization": false,
    "max_clients": 20,
    "idle_timeout": 180,
    "keep_alive": 10,
    "security": {
        "min_tls_version": "1.3",
        "cipher_suites": ["TLS_AES_256_GCM_SHA384", "TLS_CHACHA20_POLY1305_SHA256"],
        "auth_timeout": 10,
        "max_auth_attempts": 3
    }
}
```

### سرور با تمرکز بر مقیاس‌پذیری

```json
{
    "listen_addr": "0.0.0.0:4433",
    "cert_path": "/etc/quicvpn/server.crt",
    "key_path": "/etc/quicvpn/server.key",
    "users_file": "/etc/quicvpn/users.json",
    "log_level": "error",
    "ip_pool": "10.8.0.0/16",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "enable_ipv6": true,
    "game_optimization": true,
    "max_clients": 1000,
    "idle_timeout": 600,
    "keep_alive": 15,
    "performance": {
        "worker_threads": 16,
        "connection_buffer_size": 10000,
        "stream_receive_window": 15728640,
        "max_concurrent_streams": 100
    }
}
``` 