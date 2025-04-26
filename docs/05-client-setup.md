# راه‌اندازی کلاینت

این بخش شامل راهنمای کامل راه‌اندازی کلاینت QUIC VPN با تمرکز بر پلتفرم ویندوز است.

## پیکربندی کلاینت

### نیازمندی‌های سیستم

برای اجرای کلاینت QUIC VPN، سیستم شما باید دارای شرایط زیر باشد:

| مورد | حداقل | توصیه شده |
|------|-------|-----------|
| سیستم عامل | ویندوز 10 (نسخه 1903 یا بالاتر) | ویندوز 10/11 آخرین نسخه |
| CPU | پردازنده دو هسته‌ای، 1.5 گیگاهرتز | پردازنده چهار هسته‌ای، 2+ گیگاهرتز |
| RAM | 2 گیگابایت | 4+ گیگابایت |
| فضای دیسک | 50 مگابایت | 100+ مگابایت |
| شبکه | اتصال اینترنت پایدار | اتصال پهنای باند بالا با تأخیر کم |

### فایل پیکربندی

کلاینت QUIC VPN از یک فایل پیکربندی JSON استفاده می‌کند که به صورت پیش‌فرض در مسیر نصب برنامه با نام `client_config.json` ذخیره می‌شود. ساختار این فایل به شرح زیر است:

```json
{
    "server_addr": "example.com:4433",
    "username": "user1",
    "password": "password_hash",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "auto_reconnect": true,
    "reconnect_delay": 5,
    "gaming_optimization": true,
    "game_type": "Default",
    "log_level": "info",
    "gui_theme": "dark",
    "tray_on_close": true,
    "start_with_windows": false,
    "connection_timeout": 30
}
```

#### گزینه‌های پیکربندی

| گزینه | توضیح | مقدار پیش‌فرض |
|-------|-------|---------------|
| `server_addr` | آدرس:پورت سرور QUIC VPN | - |
| `username` | نام کاربری برای احراز هویت | - |
| `password` | رمز عبور (هش شده) | - |
| `dns_servers` | سرورهای DNS مورد استفاده | `["8.8.8.8", "1.1.1.1"]` |
| `mtu` | حداکثر اندازه بسته انتقال | `1400` |
| `auto_reconnect` | اتصال مجدد خودکار در صورت قطعی | `true` |
| `reconnect_delay` | تأخیر بین تلاش‌های اتصال مجدد (ثانیه) | `5` |
| `gaming_optimization` | فعال‌سازی بهینه‌سازی‌های گیمینگ | `true` |
| `game_type` | نوع بازی برای بهینه‌سازی‌های خاص | `"Default"` |
| `log_level` | سطح لاگ (`error`, `warn`, `info`, `debug`, `trace`) | `"info"` |
| `gui_theme` | تم رابط کاربری (`light`, `dark`, `system`) | `"dark"` |
| `tray_on_close` | حداقل کردن به تری هنگام بستن | `true` |
| `start_with_windows` | شروع خودکار با ویندوز | `false` |
| `connection_timeout` | زمان انتظار برای برقراری اتصال (ثانیه) | `30` |

## نصب و راه‌اندازی کلاینت

### نصب از طریق نصب‌کننده

ساده‌ترین روش برای نصب کلاینت QUIC VPN استفاده از نصب‌کننده ویندوز است:

1. فایل `QuicVPN-Setup.exe` را از [وب‌سایت رسمی](https://example.com/download) یا [صفحه Releases در GitHub](https://github.com/username/quicvpn/releases/latest) دانلود کنید.

2. روی فایل دانلود شده دابل کلیک کنید و مراحل نصب را دنبال کنید:
   - قبول توافق‌نامه کاربر
   - انتخاب مسیر نصب (پیش‌فرض: `C:\Program Files\QUIC VPN`)
   - انتخاب گزینه‌های نصب (نصب به عنوان سرویس، ایجاد میانبر در دسکتاپ، اجرا با شروع ویندوز)
   - کلیک روی "نصب" و منتظر اتمام نصب بمانید

3. پس از اتمام نصب، برنامه به صورت خودکار اجرا می‌شود و از شما اطلاعات اتصال را درخواست می‌کند.

### نصب دستی

اگر ترجیح می‌دهید کلاینت را به صورت دستی نصب کنید:

1. فایل `quicvpn-client-windows.zip` را از [وب‌سایت رسمی](https://example.com/download) یا [صفحه Releases در GitHub](https://github.com/username/quicvpn/releases/latest) دانلود کنید.

2. فایل ZIP را در مسیر دلخواه (مثلاً `C:\Program Files\QUIC VPN`) استخراج کنید.

3. یک فایل `client_config.json` در همان مسیر با محتوای مناسب ایجاد کنید یا از طریق خط فرمان پیکربندی کنید:
   ```
   cd "C:\Program Files\QUIC VPN"
   .\client.exe init --server your-server-ip:4433 --username your-username --password your-password --game-optimized
   ```

4. برای نصب به عنوان سرویس ویندوز:
   ```
   .\client.exe install
   ```

5. برای ایجاد میانبر در دسکتاپ:
   - راست کلیک روی دسکتاپ > New > Shortcut
   - برای آدرس وارد کنید: `"C:\Program Files\QUIC VPN\client.exe" connect`
   - نام میانبر را "QUIC VPN" بگذارید

## اتصال به سرور

### استفاده از رابط گرافیکی

کلاینت QUIC VPN دارای یک رابط گرافیکی ساده و کاربرپسند است:

1. برنامه QUIC VPN را از منوی استارت یا میانبر دسکتاپ اجرا کنید.

2. در صفحه اصلی برنامه:
   - اگر قبلاً پیکربندی نکرده‌اید، اطلاعات سرور و کاربر را وارد کنید
   - دکمه "Connect" را کلیک کنید
   - منتظر برقراری اتصال بمانید

3. پس از اتصال موفق، وضعیت اتصال، آدرس IP، و آمار انتقال داده نمایش داده می‌شود.

4. برای قطع اتصال، دکمه "Disconnect" را کلیک کنید.

### استفاده از خط فرمان

کلاینت QUIC VPN را می‌توان از طریق خط فرمان نیز کنترل کرد:

```powershell
# اتصال با استفاده از تنظیمات فایل پیکربندی
.\client.exe connect

# اتصال با مشخص کردن سرور و نام کاربری
.\client.exe connect --server example.com:4433 --username user1

# اتصال با بهینه‌سازی برای بازی‌های FPS
.\client.exe connect --game-type FPS

# قطع اتصال
.\client.exe disconnect

# نمایش وضعیت
.\client.exe status
```

### گزینه‌های خط فرمان

کلاینت QUIC VPN دارای گزینه‌های متعددی در خط فرمان است:

| دستور | توضیح |
|-------|-------|
| `init` | راه‌اندازی اولیه و ایجاد فایل پیکربندی |
| `connect` | اتصال به سرور |
| `disconnect` | قطع اتصال از سرور |
| `status` | نمایش وضعیت اتصال فعلی |
| `install` | نصب به عنوان سرویس ویندوز |
| `uninstall` | حذف سرویس ویندوز |
| `start` | شروع سرویس |
| `stop` | توقف سرویس |
| `version` | نمایش نسخه برنامه |
| `help` | نمایش راهنما |

## نصب به عنوان سرویس ویندوز

نصب QUIC VPN به عنوان سرویس ویندوز باعث می‌شود حتی بدون ورود کاربر به سیستم، VPN فعال باشد.

### نصب سرویس

```powershell
# اجرا به عنوان Administrator
cd "C:\Program Files\QUIC VPN"
.\client.exe install
```

این دستور یک سرویس ویندوز به نام "QUIC VPN Service" ایجاد می‌کند که می‌تواند با شروع سیستم به صورت خودکار اجرا شود.

### تنظیمات راه‌اندازی سرویس

برای تغییر نحوه راه‌اندازی سرویس:

1. از طریق `services.msc`:
   - کلید Win+R را فشار دهید و `services.msc` را وارد کنید
   - سرویس "QUIC VPN Service" را پیدا کنید
   - روی آن دابل کلیک کنید
   - در فیلد "Startup type" گزینه مناسب را انتخاب کنید (Automatic, Manual, Disabled)

2. از طریق خط فرمان:
   ```powershell
   # تنظیم راه‌اندازی خودکار
   sc.exe config QuicVpnService start= auto

   # تنظیم راه‌اندازی دستی
   sc.exe config QuicVpnService start= demand

   # غیرفعال کردن
   sc.exe config QuicVpnService start= disabled
   ```

### مدیریت سرویس

برای مدیریت سرویس می‌توانید از دستورات زیر استفاده کنید:

```powershell
# شروع سرویس
sc.exe start QuicVpnService
# یا
.\client.exe start

# توقف سرویس
sc.exe stop QuicVpnService
# یا
.\client.exe stop

# وضعیت سرویس
sc.exe query QuicVpnService
```

## مدیریت اتصال‌ها

### پروفایل‌های اتصال

کلاینت QUIC VPN از چندین پروفایل اتصال پشتیبانی می‌کند، که می‌توانید برای سرورها یا کاربردهای مختلف ایجاد کنید:

1. از طریق رابط گرافیکی:
   - به تب "Profiles" بروید
   - روی دکمه "Add New Profile" کلیک کنید
   - اطلاعات پروفایل جدید را وارد کنید (نام، سرور، نام کاربری، رمز عبور، تنظیمات)
   - روی "Save" کلیک کنید

2. از طریق خط فرمان:
   ```powershell
   # ایجاد پروفایل جدید
   .\client.exe profile add --name "Gaming" --server game.example.com:4433 --username user1 --password secret --game-optimized --game-type FPS

   # لیست پروفایل‌ها
   .\client.exe profile list

   # اتصال با استفاده از پروفایل
   .\client.exe connect --profile Gaming
   ```

### اتصال خودکار

برای تنظیم اتصال خودکار VPN هنگام شروع ویندوز:

1. از طریق رابط گرافیکی:
   - به تب "Settings" بروید
   - گزینه "Start with Windows" را فعال کنید
   - پروفایل پیش‌فرض برای اتصال خودکار را انتخاب کنید

2. از طریق خط فرمان:
   ```powershell
   # فعال‌سازی شروع با ویندوز
   .\client.exe config set start_with_windows true

   # تنظیم پروفایل پیش‌فرض
   .\client.exe config set default_profile Gaming
   ```

### اتصال مجدد خودکار

برای تنظیم اتصال مجدد خودکار در صورت قطع شدن اتصال:

1. از طریق رابط گرافیکی:
   - به تب "Settings" بروید
   - گزینه "Auto reconnect" را فعال کنید
   - زمان تأخیر بین تلاش‌های اتصال مجدد را تنظیم کنید

2. از طریق خط فرمان:
   ```powershell
   # فعال‌سازی اتصال مجدد خودکار
   .\client.exe config set auto_reconnect true

   # تنظیم تأخیر بین تلاش‌ها (به ثانیه)
   .\client.exe config set reconnect_delay 5
   ```

## تنظیمات پیشرفته

### بهینه‌سازی‌های گیمینگ

برای بهبود تجربه گیمینگ، می‌توانید تنظیمات مخصوص بازی را فعال کنید:

1. از طریق رابط گرافیکی:
   - به تب "Settings" بروید
   - به بخش "Gaming Optimization" بروید
   - گزینه "Enable gaming optimizations" را فعال کنید
   - نوع بازی مورد نظر را انتخاب کنید

2. از طریق خط فرمان:
   ```powershell
   # فعال‌سازی بهینه‌سازی‌های گیمینگ
   .\client.exe config set gaming_optimization true

   # تنظیم نوع بازی
   .\client.exe config set game_type FPS
   ```

پروفایل‌های بازی موجود عبارتند از:
- `FPS`: برای بازی‌های تیراندازی اول شخص مانند CS:GO، Valorant، Call of Duty
- `MOBA`: برای بازی‌های آنلاین چندنفره مانند Dota 2، League of Legends
- `MMO`: برای بازی‌های نقش‌آفرینی آنلاین گسترده مانند World of Warcraft
- `Racing`: برای بازی‌های مسابقه‌ای مانند Forza، iRacing
- `Default`: تنظیمات متعادل برای اکثر بازی‌ها

### تنظیمات Split Tunneling

قابلیت Split Tunneling به شما امکان می‌دهد انتخاب کنید کدام برنامه‌ها از VPN استفاده کنند و کدام برنامه‌ها مستقیماً به اینترنت متصل شوند:

1. از طریق رابط گرافیکی:
   - به تب "Split Tunneling" بروید
   - یکی از حالت‌های زیر را انتخاب کنید:
     - "All traffic through VPN" (همه ترافیک از طریق VPN)
     - "Exclude selected apps" (استثنا کردن برنامه‌های انتخاب شده)
     - "Include only selected apps" (فقط شامل برنامه‌های انتخاب شده)
   - برنامه‌های مورد نظر را از لیست انتخاب کنید یا با دکمه "Add" اضافه کنید

2. از طریق خط فرمان:
   ```powershell
   # تنظیم حالت Split Tunneling
   .\client.exe tunnel mode exclude

   # افزودن برنامه به لیست استثناها
   .\client.exe tunnel add "C:\Program Files\Mozilla Firefox\firefox.exe"

   # حذف برنامه از لیست
   .\client.exe tunnel remove "C:\Program Files\Mozilla Firefox\firefox.exe"

   # نمایش لیست برنامه‌ها
   .\client.exe tunnel list
   ```

### تنظیمات DNS

برای تغییر سرورهای DNS مورد استفاده:

1. از طریق رابط گرافیکی:
   - به تب "Settings" بروید
   - به بخش "Network" بروید
   - سرورهای DNS را وارد کنید یا از پیش‌تنظیم‌ها انتخاب کنید

2. از طریق خط فرمان:
   ```powershell
   # تنظیم سرورهای DNS
   .\client.exe config set dns_servers ["8.8.8.8","1.1.1.1"]

   # استفاده از DNS سرور
   .\client.exe config set use_server_dns true
   ```

پیش‌تنظیم‌های DNS موجود:
- Google: 8.8.8.8, 8.8.4.4
- Cloudflare: 1.1.1.1, 1.0.0.1
- OpenDNS: 208.67.222.222, 208.67.220.220
- Quad9: 9.9.9.9, 149.112.112.112

## عیب‌یابی کلاینت

### مشکل: ناتوانی در نصب درایور TUN

**علائم**:
- خطای "Failed to install TUN driver" هنگام نصب یا اجرای برنامه
- ناتوانی در ایجاد اینترفیس مجازی

**راه حل‌ها**:
1. اطمینان از اجرا با دسترسی Administrator:
   - راست کلیک روی فایل اجرایی و انتخاب "Run as administrator"

2. بررسی نصب TAP Windows Adapter:
   - نصب OpenVPN برای دریافت درایور TAP
   - از Device Manager بررسی کنید که آداپتور TAP نصب شده باشد

3. نصب مجدد درایور:
   ```powershell
   cd "C:\Program Files\QUIC VPN\drivers"
   .\tap-windows-install.exe /S
   ```

4. غیرفعال کردن موقت آنتی‌ویروس یا فایروال که ممکن است با نصب درایور تداخل داشته باشد.

### مشکل: خطای اتصال به سرور

**علائم**:
- پیام خطای "Connection failed" یا "Server unreachable"
- ناتوانی در برقراری اتصال با سرور

**راه حل‌ها**:
1. بررسی اتصال اینترنت:
   ```powershell
   Test-NetConnection -ComputerName example.com -Port 4433
   ```

2. بررسی صحت آدرس سرور:
   - اطمینان از صحت آدرس و پورت وارد شده
   - امتحان کردن آدرس IP به جای نام دامنه

3. بررسی فایروال ویندوز:
   - اطمینان از اجازه دسترسی برنامه به شبکه در فایروال
   ```powershell
   # افزودن استثنا به فایروال
   New-NetFirewallRule -DisplayName "QUIC VPN Client" -Direction Outbound -Program "C:\Program Files\QUIC VPN\client.exe" -Action Allow
   ```

4. بررسی محدودیت‌های ISP:
   - برخی ISPها ممکن است پروتکل QUIC را محدود کنند
   - امتحان کردن اتصال از طریق شبکه‌های مختلف

### مشکل: قطع مکرر اتصال

**علائم**:
- قطع و وصل شدن مکرر اتصال VPN
- پیام‌های "Connection lost, trying to reconnect..."

**راه حل‌ها**:
1. تنظیم keepalive با فاصله کمتر:
   ```powershell
   .\client.exe config set keep_alive 2
   ```

2. افزایش زمان timeout:
   ```powershell
   .\client.exe config set connection_timeout 60
   ```

3. بررسی کیفیت اتصال اینترنت:
   ```powershell
   ping -t 8.8.8.8
   ```

4. غیرفعال کردن موقت برنامه‌های مدیریت شبکه یا آنتی‌ویروس که ممکن است با اتصال تداخل داشته باشند.

### مشکل: عملکرد ضعیف یا تأخیر بالا

**علائم**:
- سرعت پایین هنگام استفاده از VPN
- تأخیر بالا در بازی‌ها علیرغم فعال بودن بهینه‌سازی‌های گیمینگ

**راه حل‌ها**:
1. انتخاب سرور نزدیک‌تر:
   - اتصال به سروری که از نظر جغرافیایی نزدیک‌تر است

2. تنظیم MTU بهینه:
   ```powershell
   # تست MTU بهینه
   ping example.com -f -l 1500
   
   # تنظیم MTU جدید
   .\client.exe config set mtu 1400
   ```

3. بهینه‌سازی تنظیمات گیمینگ:
   - انتخاب پروفایل بازی مناسب
   ```powershell
   .\client.exe config set game_type FPS
   ```

4. استفاده از Split Tunneling:
   - فقط ترافیک بازی را از VPN عبور دهید
   ```powershell
   .\client.exe tunnel mode include
   .\client.exe tunnel add "C:\Games\game.exe"
   ```

### مشکل: تداخل با سایر VPNها

**علائم**:
- خطا هنگام اتصال در صورت فعال بودن سایر VPNها
- مشکلات مسیریابی شبکه

**راه حل‌ها**:
1. غیرفعال کردن سایر VPNها قبل از اتصال:
   - اطمینان حاصل کنید که VPN دیگری فعال نیست

2. بررسی جدول مسیریابی:
   ```powershell
   route print
   ```

3. پاک کردن مسیرهای احتمالی تداخل کننده:
   ```powershell
   # حذف مسیرهای مشکل‌ساز
   route delete 0.0.0.0 mask 0.0.0.0
   ```

4. راه‌اندازی مجدد سرویس شبکه:
   ```powershell
   Restart-Service -Name "Wired AutoConfig" -Force
   Restart-Service -Name "WLAN AutoConfig" -Force
   ```

## بروزرسانی کلاینت

### بروزرسانی خودکار

کلاینت QUIC VPN به صورت پیش‌فرض هنگام اجرا، وجود نسخه جدید را بررسی می‌کند:

1. از طریق رابط گرافیکی:
   - اگر نسخه جدیدی موجود باشد، یک اعلان نمایش داده می‌شود
   - با کلیک روی "Update Now"، بروزرسانی شروع می‌شود
   - برنامه به صورت خودکار دانلود و نصب نسخه جدید را انجام می‌دهد

2. تنظیمات بروزرسانی خودکار:
   - در تب "Settings" به بخش "Updates" بروید
   - می‌توانید بررسی خودکار بروزرسانی را فعال یا غیرفعال کنید
   - می‌توانید انتخاب کنید که بروزرسانی‌ها به صورت خودکار نصب شوند یا فقط اطلاع‌رسانی شوند

### بروزرسانی دستی

برای بروزرسانی دستی کلاینت:

1. از طریق رابط گرافیکی:
   - به تب "About" بروید
   - روی دکمه "Check for Updates" کلیک کنید

2. از طریق خط فرمان:
   ```powershell
   # بررسی وجود بروزرسانی
   .\client.exe update check

   # دانلود و نصب بروزرسانی
   .\client.exe update install
   ```

3. دانلود و نصب دستی:
   - آخرین نسخه را از [وب‌سایت رسمی](https://example.com/download) دانلود کنید
   - کلاینت فعلی را ببندید
   - نصب‌کننده جدید را اجرا کنید و مراحل نصب را دنبال کنید

## حذف نصب

برای حذف کامل QUIC VPN از سیستم:

1. از طریق Control Panel:
   - به Control Panel > Programs > Programs and Features بروید
   - QUIC VPN را پیدا کرده و "Uninstall" را انتخاب کنید
   - مراحل حذف نصب را دنبال کنید

2. از طریق خط فرمان:
   ```powershell
   # اجرا به عنوان Administrator
   # حذف سرویس ویندوز
   .\client.exe uninstall

   # حذف کامل برنامه
   .\client.exe uninstall --remove-all
   ```

3. حذف دستی باقیمانده‌ها:
   - پس از حذف نصب، ممکن است برخی فایل‌ها و تنظیمات باقی بمانند
   - فولدرهای زیر را حذف کنید:
     - `C:\Program Files\QUIC VPN`
     - `C:\ProgramData\QUIC VPN`
     - `%APPDATA%\QUIC VPN`
   - درایور TUN/TAP را از Device Manager حذف کنید

## مثال‌های پیکربندی

### پیکربندی بهینه برای گیمینگ

```json
{
    "server_addr": "gaming.example.com:4433",
    "username": "gamer1",
    "password": "password_hash",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1400,
    "auto_reconnect": true,
    "reconnect_delay": 2,
    "gaming_optimization": true,
    "game_type": "FPS",
    "log_level": "warn",
    "keep_alive": 2,
    "connection_timeout": 20
}
```

### پیکربندی بهینه برای امنیت

```json
{
    "server_addr": "secure.example.com:4433",
    "username": "user1",
    "password": "password_hash",
    "dns_servers": ["9.9.9.9", "1.0.0.1"],
    "mtu": 1400,
    "auto_reconnect": true,
    "reconnect_delay": 5,
    "gaming_optimization": false,
    "log_level": "info",
    "tray_on_close": true,
    "connection_timeout": 30,
    "security": {
        "verify_cert": true,
        "cert_pinning": true,
        "min_tls_version": "1.3"
    }
}
```

### پیکربندی برای استفاده با اینترنت ناپایدار

```json
{
    "server_addr": "example.com:4433",
    "username": "mobile_user",
    "password": "password_hash",
    "dns_servers": ["8.8.8.8", "1.1.1.1"],
    "mtu": 1200,
    "auto_reconnect": true,
    "reconnect_delay": 3,
    "max_reconnect_attempts": 0,
    "gaming_optimization": false,
    "log_level": "warn",
    "connection_timeout": 60,
    "idle_timeout": 1800,
    "keep_alive": 5,
    "network": {
        "roaming_friendly": true,
        "optimized_for_high_latency": true,
        "aggressive_reconnect": true
    }
}
``` 