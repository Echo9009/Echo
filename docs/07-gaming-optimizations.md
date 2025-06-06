# بهینه‌سازی‌های گیمینگ

QUIC VPN به طور خاص برای بهبود تجربه گیمینگ بهینه‌سازی شده است. در این بخش، تمام بهینه‌سازی‌های انجام شده برای کاهش تأخیر و بهبود عملکرد در بازی‌های آنلاین را بررسی می‌کنیم.

## تأثیر تأخیر در بازی‌های آنلاین

تأخیر (latency) یکی از مهم‌ترین فاکتورهای تأثیرگذار در کیفیت تجربه بازی‌های آنلاین است. این تأخیر می‌تواند به دلایل مختلفی افزایش یابد:

1. **فاصله فیزیکی** از سرور بازی
2. **مسیریابی نامناسب** توسط ISP
3. **ازدحام شبکه** در ساعات شلوغ
4. **پروتکل‌های ناکارآمد** که به درستی برای بازی بهینه نشده‌اند

QUIC VPN با بهره‌گیری از پروتکل QUIC و بهینه‌سازی‌های خاص، تلاش می‌کند تا این مشکلات را تا حد ممکن کاهش دهد.

## تنظیمات لیتنسی پایین

### 1. کاهش زمان برقراری اتصال

پروتکل QUIC به طور ذاتی برقراری اتصال سریع‌تری نسبت به TCP+TLS دارد:

```rust
// در تنظیمات QUIC
let mut server_config = QuinnServerConfig::with_crypto(Arc::new(server_crypto_config));
```

مزیت 1-RTT handshake در QUIC به جای 3-RTT در TCP+TLS باعث می‌شود اتصال اولیه حداقل دو برابر سریع‌تر انجام شود.

### 2. تنظیم keepalive با فاصله کم

برای حفظ اتصال و جلوگیری از timeout در NAT یا فایروال‌ها، فاصله keepalive به 5 ثانیه کاهش یافته است:

```rust
// در server/main.rs و client/vpn_client.rs
transport_config.keep_alive_interval(Some(std::time::Duration::from_secs(5)));
```

این تنظیم از قطع شدن اتصال در میانه بازی جلوگیری می‌کند.

### 3. تنظیم RTT اولیه

برای بهبود رفتار پروتکل در لحظات اولیه اتصال، یک RTT اولیه کمتر تنظیم شده است:

```rust
// در حالت gaming_optimization
transport_config.initial_rtt(std::time::Duration::from_millis(100));
```

این تنظیم باعث می‌شود الگوریتم کنترل ازدحام در ابتدا محافظه‌کارانه‌تر عمل نکند و سریع‌تر به سرعت مطلوب برسد.

## تنظیمات جریان داده

### 1. اولویت‌بندی داده‌های بلادرنگ

در کد کلاینت و سرور، سیستمی برای تشخیص و اولویت‌دهی به بسته‌های حساس به تأخیر پیاده‌سازی شده است:

```rust
// در client/vpn_client.rs
if self.config.gaming_optimization {
    self.send_message(
        &mut send,
        &Message::GameOptimizationInfo {
            game_type: self.config.game_type.clone().unwrap_or_else(|| "default".to_string()),
            latency_priority: true,
        },
    ).await?;
}
```

این اطلاعات به سرور ارسال می‌شود تا بتواند ترافیک کاربر را بهینه‌تر مدیریت کند.

### 2. بافر دریافت نامحدود برای داده‌ها

برای جلوگیری از محدودیت در دریافت داده‌ها، بافر دریافت به صورت نامحدود تنظیم شده است:

```rust
// در حالت gaming_optimization
transport_config.datagram_receive_buffer_size(None);
```

این تنظیم باعث می‌شود هیچ بسته‌ای به دلیل پر شدن بافر از دست نرود.

## الگوریتم‌های کنترل ازدحام

### 1. تنظیمات ویژه QUIC

QUIC از الگوریتم‌های کنترل ازدحام پیشرفته‌تری نسبت به TCP استفاده می‌کند که بهتر می‌تواند با شرایط متغیر شبکه سازگار شود. این موارد شامل:

- **بازیابی سریع‌تر از اتلاف بسته**
- **تشخیص ازدحام براساس تغییر RTT** (نه فقط از دست دادن بسته)
- **پاسخ سریع‌تر به تغییرات پهنای باند**

### 2. تنظیمات idle timeout

برای جلوگیری از قطع اتصال در زمان‌های کوتاه عدم فعالیت:

```rust
transport_config.max_idle_timeout(Some(std::time::Duration::from_secs(30).try_into()?));
```

این زمان به اندازه کافی طولانی است تا در مواقعی که بازی داده زیادی ندارد، اتصال حفظ شود، اما به اندازه‌ای کوتاه است که منابع سرور را هدر ندهد.

## بهینه‌سازی برای بازی‌های مختلف

QUIC VPN می‌تواند براساس نوع بازی تنظیمات خود را تغییر دهد. این ویژگی از طریق پارامتر `game_type` پیاده‌سازی شده است:

```rust
// در پیکربندی کلاینت
game_type: if game_optimized { Some("default".to_string()) } else { None },
```

### پروفایل‌های از پیش تعریف شده برای بازی‌ها

در پیاده‌سازی فعلی، پروفایل‌های زیر در نظر گرفته شده است:

| نوع بازی | تنظیمات ویژه |
|----------|--------------|
| FPS | اولویت بسیار بالا برای بسته‌های کوچک، تأخیر کمتر |
| MOBA | تعادل بین تأخیر و پایداری |
| MMO | اولویت پایداری اتصال بر تأخیر |
| Racing | تأخیر کم با اولویت بالا |
| Default | تنظیمات متعادل برای اکثر بازی‌ها |

برای کار با این پروفایل‌ها، کافی است در زمان اتصال یا پیکربندی، نوع بازی را مشخص کنید:

```bash
# تنظیم پیکربندی با بهینه‌سازی برای بازی‌های FPS
.\client.exe init --server your-server-ip:4433 --username your-username --password your-password --game-optimized --game-type="FPS"
```

## تنظیمات TUN device

علاوه بر تنظیمات QUIC، تنظیمات TUN device نیز برای بهبود عملکرد گیمینگ بهینه شده است:

### 1. MTU بهینه

```rust
// در پیکربندی پیش‌فرض
mtu: 1400,
```

این اندازه MTU به نحوی انتخاب شده که از فرگمنت شدن بسته‌ها جلوگیری کند، اما به اندازه کافی بزرگ باشد که سربار زیادی ایجاد نکند.

### 2. اولویت‌بندی ترافیک در سیستم عامل

در لینوکس، می‌توان با استفاده از tc (traffic control) اولویت ترافیک را افزایش داد:

```bash
# تنظیم اولویت بالا برای interface TUN
sudo tc qdisc add dev quicvpn0 root handle 1: prio bands 3
sudo tc filter add dev quicvpn0 parent 1: protocol ip prio 1 u32 match ip sport 1195 0xffff flowid 1:1
```

## پیاده‌سازی پیشرفته

### 1. داده‌های تشخیصی

QUIC VPN اطلاعات تشخیصی مهمی را جمع‌آوری می‌کند که می‌تواند برای بهینه‌سازی بیشتر استفاده شود:

```rust
// در پروتکل ارتباطی
Stats {
    bytes_sent: u64,
    bytes_received: u64,
    packets_sent: u64,
    packets_received: u64,
    latency_ms: u32,
}
```

این اطلاعات می‌تواند به کاربر نمایش داده شود یا برای تنظیم خودکار پارامترهای بهینه‌سازی استفاده شود.

### 2. مسیریابی هوشمند

برای بهبود بیشتر تأخیر، مسیریابی هوشمند می‌تواند براساس اطلاعات RTT به سرورهای بازی مختلف انجام شود:

```rust
// نمونه کد مسیریابی هوشمند
RouteUpdate {
    routes: Vec<RouteInfo>,
}
```

## عیب‌یابی مشکلات عملکرد گیمینگ

### مشکل: تأخیر بالا علیرغم فعال بودن بهینه‌سازی‌های گیمینگ

**علائم**:
- تأخیر بالا در بازی با وجود فعال بودن بهینه‌سازی‌های گیمینگ
- جیتر (تغییرات تأخیر) زیاد

**راه حل‌ها**:
1. بررسی فعال بودن بهینه‌سازی‌های گیمینگ:
   ```bash
   # در کلاینت، بررسی فایل پیکربندی
   cat client_config.json | grep gaming_optimization
   # باید "gaming_optimization": true باشد
   ```

2. بررسی روتر یا فایروال:
   - برخی روترها QUIC را محدود می‌کنند
   - اطمینان از عدم محدودیت QoS برای ترافیک QUIC

3. انتخاب سرور نزدیک‌تر:
   ```bash
   # تست ping به سرور
   ping your-server-ip
   # اگر ping بالاست، سروری نزدیک‌تر انتخاب کنید
   ```

4. تست با نوع بازی مختلف:
   ```bash
   # تنظیم مجدد با نوع بازی مشخص
   .\client.exe init --server your-server-ip:4433 --username your-username --password your-password --game-optimized --game-type="FPS"
   ```

### مشکل: قطع و وصل شدن مکرر در حین بازی

**علائم**:
- قطع و وصل شدن مکرر اتصال VPN در حین بازی
- پیام‌های خطای اتصال در لاگ‌ها

**راه حل‌ها**:
1. افزایش زمان keepalive:
   ```bash
   # ویرایش دستی فایل کد و کامپایل مجدد
   # transport_config.keep_alive_interval(Some(std::time::Duration::from_secs(2))); // مقدار کمتر
   ```

2. بررسی پایداری اتصال اینترنت:
   ```bash
   # تست پایداری اتصال
   ping -t 8.8.8.8
   # بررسی packet loss و تغییرات زیاد در زمان پاسخ
   ```

3. بررسی محدودیت‌های ISP برای QUIC:
   - برخی ISPها ممکن است QUIC را محدود کنند
   - امتحان کردن پورت متفاوت در تنظیمات سرور

### مشکل: مصرف بالای CPU

**علائم**:
- استفاده بالای CPU در حین استفاده از VPN
- کاهش FPS در بازی

**راه حل‌ها**:
1. کاهش تعداد استریم‌های باز:
   - اصلاح کد کلاینت برای استفاده از استریم‌های دائمی (به بخش مدیریت استریم‌ها مراجعه کنید)

2. تنظیم MTU:
   ```bash
   # در فایل پیکربندی سرور
   # تنظیم MTU بهینه‌تر برای کاهش پردازش
   # "mtu": 1300,
   ```

3. بررسی منطق پردازش بسته‌ها:
   - اطمینان از عدم وجود حلقه‌های اضافی یا پردازش‌های غیرضروری
   - بررسی الگوریتم‌های رمزنگاری استفاده شده

## بهینه‌سازی‌های آینده

برای نسخه‌های آتی QUIC VPN، بهینه‌سازی‌های بیشتری در نظر گرفته شده است:

1. **تشخیص خودکار نوع بازی**: شناسایی الگوی ترافیک و تنظیم خودکار پارامترها
2. **اولویت‌بندی هوشمند بسته‌ها**: براساس محتوا و اندازه بسته‌ها
3. **مسیریابی چندمسیره (Multipath)**: استفاده از چندین مسیر شبکه به صورت همزمان
4. **بهینه‌سازی براساس یادگیری ماشین**: تنظیم پارامترها براساس داده‌های هزاران کاربر 