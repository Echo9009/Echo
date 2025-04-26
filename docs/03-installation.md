# نصب و راه‌اندازی

این بخش شامل دستورالعمل‌های کامل برای نصب و راه‌اندازی QUIC VPN در محیط‌های مختلف است.

## پیش‌نیازها

قبل از نصب و استفاده از QUIC VPN، مطمئن شوید که سیستم شما پیش‌نیازهای زیر را دارد:

### برای توسعه و کامپایل:

1. **Rust و Cargo**:
   - نسخه 1.67 یا بالاتر
   - نصب از طریق [rustup](https://rustup.rs/)
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **کتابخانه‌های توسعه**:
   
   برای لینوکس (Ubuntu/Debian):
   ```bash
   sudo apt update
   sudo apt install build-essential pkg-config libssl-dev
   ```
   
   برای لینوکس (Fedora/CentOS):
   ```bash
   sudo dnf install gcc make pkgconfig openssl-devel
   ```
   
   برای ویندوز:
   - نصب [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
   - نصب [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html)

### برای اجرا:

1. **سرور لینوکس**:
   - لینوکس با کرنل 3.17+
   - دسترسی root برای ایجاد TUN device
   - فایروال تنظیم‌شده برای اجازه به ترافیک UDP در پورت مورد نظر (پیش‌فرض: 4433)

2. **کلاینت ویندوز**:
   - ویندوز 10 یا 11
   - دسترسی Administrator برای نصب و پیکربندی TUN adapter
   - .NET Framework 4.5 یا بالاتر (برای نصب سرویس ویندوز)

## نصب از سورس

### کلون و کامپایل پروژه

1. **دریافت کد منبع**:
   ```bash
   git clone https://github.com/username/quicvpn.git
   cd quicvpn
   ```

2. **کامپایل پروژه**:
   ```bash
   cargo build --release
   ```
   
   این دستور سه باینری اصلی را در دایرکتوری `target/release` ایجاد می‌کند:
   - `quicvpn`: اجرایی اصلی پروژه
   - `server`: سرور QUIC VPN
   - `client`: کلاینت QUIC VPN

3. **تست کامپایل**:
   ```bash
   cargo test
   ```
   
   این دستور تست‌های تعبیه شده در پروژه را اجرا می‌کند تا از صحت کامپایل اطمینان حاصل شود.

### نصب سرور (لینوکس)

1. **انتقال فایل اجرایی**:
   ```bash
   sudo cp target/release/server /usr/local/bin/quicvpn-server
   ```

2. **تنظیم دسترسی‌ها**:
   ```bash
   sudo chmod +x /usr/local/bin/quicvpn-server
   ```

3. **ایجاد دایرکتوری پیکربندی**:
   ```bash
   sudo mkdir -p /etc/quicvpn
   ```

4. **تولید گواهینامه و فایل پیکربندی اولیه**:
   ```bash
   sudo quicvpn-server --generate-cert
   sudo cp server.crt server.key config.json users.json /etc/quicvpn/
   ```

5. **تنظیم سرویس systemd** (اختیاری، برای اجرای خودکار در زمان راه‌اندازی سیستم):
   
   ایجاد فایل `/etc/systemd/system/quicvpn.service`:
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

   فعال‌سازی و شروع سرویس:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable quicvpn
   sudo systemctl start quicvpn
   ```

6. **تنظیم فایروال**:
   ```bash
   # برای UFW (Ubuntu)
   sudo ufw allow 4433/udp
   
   # برای firewalld (CentOS/Fedora)
   sudo firewall-cmd --permanent --add-port=4433/udp
   sudo firewall-cmd --reload
   
   # برای iptables
   sudo iptables -A INPUT -p udp --dport 4433 -j ACCEPT
   sudo netfilter-persistent save
   ```

### نصب کلاینت (ویندوز)

1. **آماده‌سازی فایل‌های کلاینت**:
   - کپی کردن فایل `target/release/client.exe` به پوشه دلخواه
   - توصیه می‌شود یک پوشه اختصاصی ایجاد کنید، مثلاً `C:\Program Files\QUIC VPN`

2. **تنظیم پیکربندی اولیه**:
   ```powershell
   # اجرا به عنوان Administrator
   cd "C:\Program Files\QUIC VPN"
   .\client.exe init --server your-server-ip:4433 --username your-username --password your-password --game-optimized
   ```

3. **نصب به عنوان سرویس ویندوز** (اختیاری):
   ```powershell
   # اجرا به عنوان Administrator
   .\client.exe install
   ```

4. **ایجاد میانبر برای دسترسی سریع** (اختیاری):
   - راست کلیک روی دسکتاپ > New > Shortcut
   - مسیر را به `"C:\Program Files\QUIC VPN\client.exe" connect` تنظیم کنید
   - نام میانبر را "QUIC VPN Connect" بگذارید

## نصب باینری‌های آماده

اگر نمی‌خواهید از سورس کامپایل کنید، می‌توانید از باینری‌های آماده استفاده کنید.

### سرور لینوکس

1. **دانلود آخرین نسخه**:
   ```bash
   curl -LO https://github.com/username/quicvpn/releases/latest/download/quicvpn-server-linux.tar.gz
   ```

2. **استخراج فایل‌ها**:
   ```bash
   tar xzf quicvpn-server-linux.tar.gz
   cd quicvpn-server
   ```

3. **نصب سرور**:
   ```bash
   sudo ./install.sh
   ```
   این اسکریپت به صورت خودکار فایل‌ها را در مسیرهای مناسب کپی می‌کند و سرویس systemd را تنظیم می‌کند.

### کلاینت ویندوز

1. **دانلود آخرین نسخه**:
   از [صفحه Releases](https://github.com/username/quicvpn/releases/latest) فایل `quicvpn-client-windows.zip` را دانلود کنید.

2. **استخراج فایل‌ها**:
   فایل ZIP را استخراج کرده و محتویات آن را در مسیر دلخواه قرار دهید.

3. **اجرای نصب‌کننده**:
   روی فایل `setup.exe` دابل کلیک کنید و مراحل نصب را دنبال کنید.

## بررسی نصب

### بررسی سرور

پس از نصب سرور، می‌توانید وضعیت آن را بررسی کنید:

```bash
# بررسی وضعیت سرویس
sudo systemctl status quicvpn

# مشاهده لاگ‌ها
sudo journalctl -u quicvpn -f

# بررسی گوش دادن پورت
sudo netstat -tulpn | grep 4433
```

### بررسی کلاینت

پس از نصب کلاینت، می‌توانید وضعیت آن را بررسی کنید:

```powershell
# بررسی وضعیت سرویس ویندوز (اگر به عنوان سرویس نصب شده باشد)
Get-Service QuicVpnService

# بررسی وضعیت اتصال
.\client.exe status
```

## عیب‌یابی نصب

### مشکلات رایج سرور

#### مشکل: خطای "Failed to create TUN device"

**علائم**:
- سرور با پیام خطای "Failed to create TUN device" شروع نمی‌شود
- در لاگ‌ها خطای مرتبط با دسترسی TUN دیده می‌شود

**راه حل‌ها**:
1. اطمینان از اجرا با دسترسی root:
   ```bash
   sudo quicvpn-server --config /etc/quicvpn/config.json
   ```

2. بررسی لود شدن ماژول tun:
   ```bash
   lsmod | grep tun
   # اگر نتیجه‌ای نداشت، ماژول را لود کنید
   sudo modprobe tun
   ```

3. بررسی دسترسی‌های فایل `/dev/net/tun`:
   ```bash
   ls -l /dev/net/tun
   # اطمینان از دسترسی مناسب
   sudo chmod 0666 /dev/net/tun
   ```

#### مشکل: سرور گوش نمی‌دهد

**علائم**:
- سرور به ظاهر بدون خطا شروع می‌شود اما به اتصالات پاسخ نمی‌دهد
- `netstat` پورت باز را نشان نمی‌دهد

**راه حل‌ها**:
1. بررسی تنظیمات آدرس گوش دادن در فایل `config.json`:
   ```bash
   cat /etc/quicvpn/config.json | grep listen_addr
   # اطمینان از صحت آدرس، باید "0.0.0.0:4433" یا آدرس IP واقعی باشد
   ```

2. بررسی فایروال:
   ```bash
   # برای UFW
   sudo ufw status
   # برای firewalld
   sudo firewall-cmd --list-all
   ```

3. بررسی اشغال بودن پورت توسط برنامه دیگر:
   ```bash
   sudo lsof -i :4433
   ```

### مشکلات رایج کلاینت

#### مشکل: خطای "Failed to create TUN device" در ویندوز

**علائم**:
- کلاینت با پیام خطای مرتبط با TUN شروع نمی‌شود
- خطای "Failed to create TUN device" در لاگ‌ها

**راه حل‌ها**:
1. نصب یا بررسی TAP-Windows Adapter:
   - نصب [OpenVPN](https://openvpn.net/community-downloads/) برای دریافت درایور TAP
   - بررسی Device Manager برای اطمینان از نصب صحیح آداپتور

2. اجرای کلاینت با دسترسی Administrator:
   - راست کلیک روی فایل اجرایی > "Run as administrator"

3. بررسی تداخل با سایر VPNها:
   - غیرفعال کردن موقت سایر سرویس‌های VPN

#### مشکل: عدم اتصال به سرور

**علائم**:
- کلاینت با پیام "Failed to connect to server" خارج می‌شود
- خطای timeout در لاگ‌ها

**راه حل‌ها**:
1. بررسی دسترسی شبکه:
   ```powershell
   Test-NetConnection -ComputerName your-server-ip -Port 4433
   ```

2. بررسی فایروال ویندوز:
   - Control Panel > Windows Defender Firewall > Allow an app through firewall
   - اضافه کردن client.exe به لیست استثناها

3. بررسی صحت پیکربندی:
   ```powershell
   type client_config.json
   # بررسی صحت آدرس سرور و پورت
   ```

## بروزرسانی

### بروزرسانی سرور

1. **بروزرسانی از سورس**:
   ```bash
   cd quicvpn
   git pull
   cargo build --release
   sudo systemctl stop quicvpn
   sudo cp target/release/server /usr/local/bin/quicvpn-server
   sudo systemctl start quicvpn
   ```

2. **بروزرسانی از باینری**:
   ```bash
   curl -LO https://github.com/username/quicvpn/releases/latest/download/quicvpn-server-linux.tar.gz
   tar xzf quicvpn-server-linux.tar.gz
   cd quicvpn-server
   sudo ./update.sh
   ```

### بروزرسانی کلاینت

1. **بروزرسانی از سورس**:
   ```powershell
   # در دایرکتوری پروژه
   git pull
   cargo build --release
   # توقف سرویس اگر نصب شده باشد
   Stop-Service QuicVpnService
   # کپی کردن فایل جدید
   Copy-Item -Force .\target\release\client.exe "C:\Program Files\QUIC VPN\"
   # شروع مجدد سرویس
   Start-Service QuicVpnService
   ```

2. **بروزرسانی از باینری**:
   - دانلود نسخه جدید
   - توقف سرویس اگر نصب شده باشد
   - اجرای نصب‌کننده جدید 