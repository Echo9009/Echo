# توسعه و مشارکت

این بخش شامل اطلاعات و راهنمایی‌هایی برای توسعه‌دهندگانی است که قصد دارند به پروژه QUIC VPN مشارکت کنند یا کد آن را درک کنند.

## ساختار پروژه

پروژه QUIC VPN به صورت ماژولار طراحی شده و از زبان Rust استفاده می‌کند. ساختار کلی پروژه به شرح زیر است:

```
quicvpn/
├── Cargo.toml           # فایل پروژه Rust و وابستگی‌ها
├── README.md           # مستندات اصلی پروژه
├── src/                # کد منبع اصلی
│   ├── common/         # کد مشترک بین کلاینت و سرور
│   │   ├── config.rs   # مدیریت پیکربندی
│   │   ├── crypto.rs   # توابع رمزنگاری
│   │   ├── error.rs    # مدیریت خطاها
│   │   ├── mod.rs      # تعریف ماژول مشترک
│   │   ├── protocol.rs # تعریف پروتکل ارتباطی
│   │   └── tun.rs      # رابط TUN/TAP
│   ├── client/         # کد کلاینت
│   │   ├── gui/        # رابط کاربری گرافیکی (ویندوز)
│   │   ├── cli.rs      # رابط خط فرمان
│   │   ├── config.rs   # مدیریت پیکربندی کلاینت
│   │   ├── main.rs     # نقطه ورود کلاینت
│   │   ├── mod.rs      # تعریف ماژول کلاینت
│   │   ├── service.rs  # مدیریت سرویس ویندوز
│   │   └── vpn.rs      # منطق اصلی VPN در کلاینت
│   └── server/         # کد سرور
│       ├── admin.rs    # رابط مدیریتی
│       ├── auth.rs     # احراز هویت
│       ├── config.rs   # مدیریت پیکربندی سرور
│       ├── ip_pool.rs  # مدیریت IP
│       ├── main.rs     # نقطه ورود سرور
│       ├── mod.rs      # تعریف ماژول سرور
│       └── vpn.rs      # منطق اصلی VPN در سرور
├── docs/               # مستندات
├── tests/              # تست‌های یکپارچگی
├── benches/            # تست‌های عملکرد
└── scripts/            # اسکریپت‌های کمکی
```

## محیط توسعه

### پیش‌نیازها

برای شروع توسعه QUIC VPN، به موارد زیر نیاز دارید:

1. **Rust و Cargo**:
   - نسخه 1.67 یا بالاتر
   - نصب از طریق [rustup](https://rustup.rs/)

2. **کتابخانه‌های توسعه**:
   - برای لینوکس:
     ```bash
     sudo apt install build-essential pkg-config libssl-dev
     ```
   - برای ویندوز:
     - نصب [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
     - نصب [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html)

3. **ابزارهای اضافی**:
   - برای توسعه رابط کاربری:
     - [GTK 3 (لینوکس)](https://www.gtk.org/)
     - یا [windows-rs (ویندوز)](https://github.com/microsoft/windows-rs)
   - برای تست:
     - [Docker](https://www.docker.com/) برای تست‌های یکپارچگی

### راه‌اندازی محیط توسعه

1. **کلون کردن مخزن**:
   ```bash
   git clone https://github.com/username/quicvpn.git
   cd quicvpn
   ```

2. **نصب ابزارهای توسعه**:
   ```bash
   # نصب ابزارهای مورد نیاز Rust
   rustup component add clippy rustfmt
   
   # نصب کرگو-واچ برای توسعه
   cargo install cargo-watch
   
   # نصب کرگو-اودیت برای بررسی امنیتی
   cargo install cargo-audit
   ```

3. **اجرای تست‌ها**:
   ```bash
   # اجرای تمام تست‌ها
   cargo test
   
   # اجرای تست‌های یک ماژول خاص
   cargo test --package quicvpn-common
   ```

4. **ساخت در حالت توسعه**:
   ```bash
   cargo build
   ```

5. **ساخت در حالت انتشار**:
   ```bash
   cargo build --release
   ```

## راهنمای توسعه‌دهندگان

### سبک کدنویسی

پروژه QUIC VPN از قراردادهای سبک کدنویسی Rust پیروی می‌کند. برای اطمینان از سازگاری کد، لطفاً به موارد زیر توجه کنید:

1. **قالب‌بندی کد**:
   - از `rustfmt` برای قالب‌بندی کد استفاده کنید
   ```bash
   cargo fmt
   ```

2. **تحلیل کد**:
   - از `clippy` برای تحلیل کد استفاده کنید
   ```bash
   cargo clippy -- -D warnings
   ```

3. **نام‌گذاری**:
   - برای نام توابع و متغیرها از `snake_case` استفاده کنید
   - برای نام ساختارها و ویژگی‌ها از `PascalCase` استفاده کنید
   - برای نام ماژول‌ها از `snake_case` استفاده کنید
   - برای ثابت‌ها از `SCREAMING_SNAKE_CASE` استفاده کنید

4. **مستندسازی**:
   - تمام توابع عمومی، ساختارها و ماژول‌ها باید دارای مستندات باشند
   - از نشانه‌گذاری Markdown در مستندات استفاده کنید
   - نمونه‌های کد را در مستندات قرار دهید

### ساخت و تست

برای توسعه QUIC VPN، از چرخه ساخت و تست زیر استفاده کنید:

1. **توسعه تکراری**:
   ```bash
   # ساخت و اجرای مجدد خودکار با تغییر کد
   cargo watch -x run
   
   # ساخت و اجرای تست‌ها با تغییر کد
   cargo watch -x test
   ```

2. **تست‌های واحد**:
   ```bash
   # اجرای تمام تست‌های واحد
   cargo test --lib
   
   # اجرای تست واحد خاص
   cargo test --lib -- tests::test_name
   ```

3. **تست‌های یکپارچگی**:
   ```bash
   # اجرای تست‌های یکپارچگی
   cargo test --test '*'
   ```

4. **تست‌های عملکرد**:
   ```bash
   # اجرای تست‌های عملکرد
   cargo bench
   ```

5. **بررسی پوشش کد**:
   ```bash
   # نصب ابزار پوشش کد
   cargo install cargo-tarpaulin
   
   # اجرای تحلیل پوشش کد
   cargo tarpaulin
   ```

### مدیریت وابستگی‌ها

برای اضافه کردن یا به‌روزرسانی وابستگی‌ها، به موارد زیر توجه کنید:

1. **اضافه کردن وابستگی جدید**:
   - وابستگی را به فایل `Cargo.toml` اضافه کنید
   - نسخه دقیق را مشخص کنید
   - امنیت وابستگی را بررسی کنید

2. **بررسی امنیتی وابستگی‌ها**:
   ```bash
   cargo audit
   ```

3. **به‌روزرسانی وابستگی‌ها**:
   ```bash
   cargo update
   ```

4. **اصول مدیریت وابستگی**:
   - حداقل وابستگی را اضافه کنید
   - از وابستگی‌های با نگهداری فعال استفاده کنید
   - مراقب حق امتیاز و مجوزها باشید

## معرفی کد

این بخش به معرفی بخش‌های اصلی کد QUIC VPN می‌پردازد تا درک بهتری از عملکرد آن داشته باشید.

### ماژول common

ماژول `common` شامل کدهای مشترک بین کلاینت و سرور است:

#### protocol.rs

این فایل تعریف پروتکل ارتباطی بین کلاینت و سرور را شامل می‌شود:

```rust
// src/common/protocol.rs

pub enum Message {
    ClientHello {
        version: u32,
        username: String,
        password_hash: String,
    },
    ServerHello {
        assigned_ip: IpAddr,
        dns_servers: Vec<IpAddr>,
        routes: Vec<Route>,
    },
    PacketData(Vec<u8>),
    KeepAlive,
    Disconnect { reason: String },
}

impl Message {
    pub fn to_bytes(&self) -> Result<Vec<u8>, ProtocolError> {
        // سریالیزه کردن پیام به بایت
    }

    pub fn from_bytes(data: &[u8]) -> Result<Self, ProtocolError> {
        // دیسریالیزه کردن پیام از بایت
    }
}
```

#### tun.rs

این فایل رابط برای کار با دستگاه‌های TUN/TAP است:

```rust
// src/common/tun.rs

pub struct TunDevice {
    handle: TunHandle,
    name: String,
    mtu: u32,
}

impl TunDevice {
    pub fn new(name: &str, mtu: u32) -> Result<Self, TunError> {
        // ایجاد دستگاه TUN/TAP
    }

    pub fn read_packet(&mut self) -> Result<Vec<u8>, TunError> {
        // خواندن بسته از دستگاه
    }

    pub fn write_packet(&mut self, packet: &[u8]) -> Result<(), TunError> {
        // نوشتن بسته به دستگاه
    }
}
```

### ماژول client

ماژول `client` شامل کد مربوط به کلاینت QUIC VPN است:

#### vpn.rs

این فایل منطق اصلی کلاینت VPN را پیاده‌سازی می‌کند:

```rust
// src/client/vpn.rs

pub struct VpnClient {
    config: ClientConfig,
    connection: Option<QuicConnection>,
    tun_device: Option<TunDevice>,
    status: VpnStatus,
}

impl VpnClient {
    pub fn new(config: ClientConfig) -> Self {
        // ایجاد یک نمونه جدید از کلاینت
    }

    pub async fn connect(&mut self) -> Result<(), VpnError> {
        // اتصال به سرور
        // برقراری اتصال QUIC
        // تبادل پیام‌های ClientHello و ServerHello
        // راه‌اندازی دستگاه TUN
        // شروع پردازش بسته‌ها
    }

    pub async fn disconnect(&mut self) -> Result<(), VpnError> {
        // قطع اتصال از سرور
    }

    async fn process_packets(&mut self) -> Result<(), VpnError> {
        // پردازش بسته‌ها بین دستگاه TUN و سرور
    }
}
```

### ماژول server

ماژول `server` شامل کد مربوط به سرور QUIC VPN است:

#### vpn.rs

این فایل منطق اصلی سرور VPN را پیاده‌سازی می‌کند:

```rust
// src/server/vpn.rs

pub struct VpnServer {
    config: ServerConfig,
    listener: QuicListener,
    clients: HashMap<String, ClientSession>,
    ip_pool: IpPool,
}

impl VpnServer {
    pub fn new(config: ServerConfig) -> Result<Self, VpnError> {
        // ایجاد یک نمونه جدید از سرور
    }

    pub async fn run(&mut self) -> Result<(), VpnError> {
        // شروع گوش دادن به اتصالات ورودی
        // پذیرش اتصالات جدید
        // مدیریت کلاینت‌های متصل
    }

    async fn handle_client(&mut self, connection: QuicConnection) -> Result<(), VpnError> {
        // دریافت ClientHello
        // احراز هویت کاربر
        // تخصیص IP
        // ارسال ServerHello
        // شروع پردازش بسته‌ها
    }

    async fn process_client_packets(&mut self, client_id: &str) -> Result<(), VpnError> {
        // پردازش بسته‌ها برای یک کلاینت خاص
    }
}
```

#### ip_pool.rs

این فایل مدیریت تخصیص آدرس IP به کلاینت‌ها را انجام می‌دهد:

```rust
// src/server/ip_pool.rs

pub struct IpPool {
    network: IpNetwork,
    used_ips: HashSet<IpAddr>,
}

impl IpPool {
    pub fn new(network: IpNetwork) -> Self {
        // ایجاد یک استخر آدرس IP جدید
    }

    pub fn allocate(&mut self) -> Result<IpAddr, IpPoolError> {
        // تخصیص یک آدرس IP آزاد
    }

    pub fn release(&mut self, ip: IpAddr) -> Result<(), IpPoolError> {
        // آزادسازی یک آدرس IP
    }
}
```

## جریان داده در QUIC VPN

برای درک بهتر نحوه عملکرد QUIC VPN، جریان داده بین کلاینت و سرور را بررسی می‌کنیم:

### 1. برقراری اتصال

```
کلاینت                                  سرور
  |                                      |
  |---------- QUIC Handshake ----------->|
  |<--------- QUIC Handshake ------------|
  |                                      |
  |---------- ClientHello -------------->|
  |                                      | -- احراز هویت کاربر
  |                                      | -- تخصیص IP
  |<--------- ServerHello ---------------|
  |                                      |
  | -- راه‌اندازی دستگاه TUN               |
  |                                      |
```

### 2. انتقال داده

```
کلاینت                                  سرور
  |                                      |
  | -- دریافت بسته از دستگاه TUN          |
  |                                      |
  |---------- PacketData --------------->|
  |                                      | -- بررسی مقصد
  |                                      | -- مسیریابی بسته
  |                                      |
  |<--------- PacketData ----------------|
  |                                      |
  | -- نوشتن بسته به دستگاه TUN           |
  |                                      |
```

### 3. حفظ اتصال و قطع اتصال

```
کلاینت                                  سرور
  |                                      |
  |---------- KeepAlive ---------------->|
  |<--------- KeepAlive ----------------|
  |                                      |
  | -- درخواست قطع اتصال                |
  |                                      |
  |---------- Disconnect --------------->|
  |<--------- Disconnect ----------------|
  |                                      |
  | -- آزادسازی منابع                   | -- آزادسازی منابع
  |                                      |
```

## نحوه مشارکت

مشارکت شما در پروژه QUIC VPN بسیار ارزشمند است. لطفاً مراحل زیر را برای مشارکت دنبال کنید:

### 1. پیدا کردن مشکل یا ویژگی

- مشکلات باز را در GitHub بررسی کنید
- اگر مشکل جدیدی پیدا کردید یا ایده‌ای برای ویژگی جدید دارید، یک issue جدید ایجاد کنید

### 2. بحث در مورد راه‌حل

- قبل از شروع به کد زدن، در مورد راه‌حل پیشنهادی خود با جامعه بحث کنید
- این کار به اطمینان از هماهنگی تلاش‌ها و پذیرش نهایی تغییرات کمک می‌کند

### 3. فرآیند توسعه

1. مخزن را fork کنید
2. یک شاخه جدید ایجاد کنید:
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. تغییرات خود را اعمال کنید
4. تست‌ها را اجرا کنید:
   ```bash
   cargo test
   ```
5. کد را قالب‌بندی کنید:
   ```bash
   cargo fmt
   ```
6. تحلیل کد را انجام دهید:
   ```bash
   cargo clippy -- -D warnings
   ```
7. تغییرات را commit کنید:
   ```bash
   git commit -m "feat: توضیح مختصر تغییرات"
   ```
8. تغییرات را به fork خود push کنید:
   ```bash
   git push origin feature/my-new-feature
   ```
9. یک pull request ایجاد کنید

### 4. قراردادهای Commit

ما از قراردادهای conventional commits پیروی می‌کنیم:

- `feat`: یک ویژگی جدید
- `fix`: رفع یک باگ
- `docs`: تغییرات مربوط به مستندات
- `style`: تغییرات مربوط به قالب‌بندی (فاصله، کاما، و غیره)
- `refactor`: بازنویسی کد بدون تغییر در عملکرد
- `perf`: تغییرات مربوط به بهبود عملکرد
- `test`: افزودن یا اصلاح تست‌ها
- `chore`: تغییرات مربوط به ساخت، ابزارها، و غیره

### 5. بررسی کد

پس از ارسال pull request، تیم توسعه QUIC VPN آن را بررسی خواهد کرد. این بررسی شامل موارد زیر است:

- بررسی صحت عملکرد
- بررسی کیفیت کد
- اجرای CI/CD و تست‌ها
- بررسی سازگاری با معماری فعلی

پس از تأیید، تغییرات شما در مخزن اصلی ادغام خواهد شد.

## راهنمای انتشار

برای انتشار نسخه جدید از QUIC VPN، مراحل زیر را دنبال کنید:

### 1. آماده‌سازی انتشار

1. به‌روزرسانی نسخه در `Cargo.toml`:
   ```toml
   [package]
   name = "quicvpn"
   version = "1.2.3"  # نسخه را به‌روز کنید
   ```

2. به‌روزرسانی CHANGELOG.md:
   ```markdown
   # تغییرات
   
   ## 1.2.3 (2023-09-15)
   
   ### ویژگی‌های جدید
   
   - ویژگی الف
   - ویژگی ب
   
   ### رفع اشکالات
   
   - رفع مشکل الف
   - رفع مشکل ب
   ```

3. ایجاد یک commit برای نسخه جدید:
   ```bash
   git add .
   git commit -m "chore: آماده‌سازی انتشار نسخه 1.2.3"
   ```

### 2. ایجاد تگ انتشار

1. ایجاد یک تگ:
   ```bash
   git tag -a v1.2.3 -m "نسخه 1.2.3"
   ```

2. ارسال تگ به مخزن:
   ```bash
   git push origin v1.2.3
   ```

### 3. ساخت باینری‌ها

1. ساخت برای لینوکس:
   ```bash
   cargo build --release --target=x86_64-unknown-linux-gnu
   ```

2. ساخت برای ویندوز:
   ```bash
   cargo build --release --target=x86_64-pc-windows-msvc
   ```

3. بسته‌بندی باینری‌ها و فایل‌های همراه:
   ```bash
   # برای لینوکس
   tar -czvf quicvpn-server-linux-v1.2.3.tar.gz -C target/x86_64-unknown-linux-gnu/release quicvpn-server
   
   # برای ویندوز
   zip -j quicvpn-client-windows-v1.2.3.zip target/x86_64-pc-windows-msvc/release/quicvpn-client.exe
   ```

### 4. انتشار در GitHub

1. ایجاد یک انتشار جدید در GitHub
2. بارگذاری باینری‌های ساخته شده
3. افزودن یادداشت‌های انتشار بر اساس CHANGELOG.md

## منابع مفید

- [مستندات Rust](https://doc.rust-lang.org/book/)
- [مستندات quinn (کتابخانه QUIC)](https://docs.rs/quinn/latest/quinn/)
- [مستندات tokio (کتابخانه async)](https://docs.rs/tokio/latest/tokio/)
- [مشخصات پروتکل QUIC](https://datatracker.ietf.org/doc/html/rfc9000)
- [مشخصات TLS 1.3](https://datatracker.ietf.org/doc/html/rfc8446) 