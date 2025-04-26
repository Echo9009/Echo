# پیوست‌ها

این بخش شامل اطلاعات تکمیلی، منابع، مراجع و واژه‌نامه تخصصی مرتبط با QUIC VPN است.

## مراجع فنی

### استانداردها و مشخصات

#### پروتکل QUIC

QUIC یک پروتکل انتقال جدید است که توسط گروه کاری IETF توسعه یافته است. استاندارد اصلی QUIC در RFC های زیر مستند شده است:

- [RFC 9000](https://datatracker.ietf.org/doc/html/rfc9000) - QUIC: پروتکل انتقال برای HTTP/3
- [RFC 9001](https://datatracker.ietf.org/doc/html/rfc9001) - استفاده از TLS برای امنیت QUIC
- [RFC 9002](https://datatracker.ietf.org/doc/html/rfc9002) - کنترل ازدحام در QUIC

مزایای اصلی QUIC نسبت به TCP عبارتند از:

1. **شروع اتصال سریع‌تر (0-RTT یا 1-RTT)**: کاهش تأخیر در برقراری اتصال
2. **چندگانگی جریان‌ها (Multiplexing)**: رفع مشکل "head-of-line blocking"
3. **جابجایی اتصال (Connection Migration)**: امکان تغییر شبکه بدون قطع اتصال
4. **رمزنگاری یکپارچه**: امنیت بالاتر با استفاده از TLS 1.3
5. **کنترل ازدحام بهبود یافته**: عملکرد بهتر در شرایط مختلف شبکه

#### TLS 1.3

TLS 1.3 در QUIC VPN برای تأمین امنیت استفاده می‌شود:

- [RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446) - پروتکل TLS نسخه 1.3

ویژگی‌های TLS 1.3:
- برقراری ارتباط سریع‌تر (1-RTT)
- امنیت پیش‌رو کامل (Perfect Forward Secrecy)
- الگوریتم‌های رمزنگاری قوی‌تر
- حذف ویژگی‌های ناامن قدیمی

#### اینترفیس TUN/TAP

QUIC VPN از اینترفیس TUN برای ایجاد تونل شبکه استفاده می‌کند:

- [تعریف TUN/TAP](https://www.kernel.org/doc/Documentation/networking/tuntap.txt) - مستندات کرنل لینوکس
- [Universal TUN/TAP Driver](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/NKEConceptual/control/control.html) - مستندات Apple
- [TAP-Windows](https://github.com/OpenVPN/tap-windows6) - پیاده‌سازی ویندوز

### کتابخانه‌های کلیدی مورد استفاده

QUIC VPN از کتابخانه‌های زیر استفاده می‌کند:

#### Quinn

[Quinn](https://github.com/quinn-rs/quinn) یک پیاده‌سازی QUIC در Rust است که هسته اصلی ارتباطات QUIC VPN را تشکیل می‌دهد.

```rust
let mut endpoint = quinn::Endpoint::builder();
endpoint.listen(server_config)
        .bind(&listen_addr)?;
```

#### Tokio

[Tokio](https://tokio.rs/) یک کتابخانه برنامه‌نویسی ناهمگام برای Rust است که برای مدیریت I/O و همزمانی استفاده می‌شود.

```rust
#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // کد اصلی برنامه
}
```

#### Rustls

[Rustls](https://github.com/rustls/rustls) کتابخانه‌ای برای پیاده‌سازی TLS در Rust است که برای امنیت اتصالات استفاده می‌شود.

```rust
let mut tls_config = rustls::ServerConfig::builder()
    .with_safe_defaults()
    .with_no_client_auth()
    .with_single_cert(certs, key)?;
```

#### Tun-tap

[Tun-tap](https://crates.io/crates/tun-tap) کتابخانه‌ای برای کار با دستگاه‌های TUN/TAP در Rust است.

```rust
let tun = tun_tap::Iface::new("quicvpn0", tun_tap::Mode::Tun)?;
```

## واژه‌نامه

### اصطلاحات تخصصی

| اصطلاح | معنی | توضیح |
|--------|------|-------|
| QUIC | Quick UDP Internet Connections | پروتکل انتقال مبتنی بر UDP که برای بهبود کارایی و امنیت طراحی شده است |
| TLS | Transport Layer Security | پروتکل رمزنگاری برای تأمین امنیت ارتباطات |
| RTT | Round-Trip Time | زمان رفت و برگشت یک بسته در شبکه |
| MTU | Maximum Transmission Unit | حداکثر اندازه بسته قابل انتقال در یک شبکه |
| NAT | Network Address Translation | فناوری تبدیل آدرس شبکه که برای اشتراک‌گذاری اتصال اینترنت استفاده می‌شود |
| VPN | Virtual Private Network | شبکه خصوصی مجازی برای ایجاد اتصال امن به شبکه‌های دیگر |
| TUN | Network TUNnel | نوعی دستگاه مجازی برای انتقال بسته‌های IP |
| TAP | Network TAP | نوعی دستگاه مجازی برای انتقال فریم‌های اترنت |
| Latency | تأخیر | زمان انتقال داده از منبع به مقصد |
| Jitter | لرزش | تغییرات در زمان تأخیر |
| Multiplexing | چندگانگی | ارسال چندین جریان داده روی یک کانال ارتباطی |
| Stream | جریان | یک مسیر ارتباطی منطقی در QUIC |
| Flow Control | کنترل جریان | مکانیزم کنترل سرعت انتقال داده برای جلوگیری از سرریز |
| Congestion Control | کنترل ازدحام | مکانیزم تنظیم نرخ ارسال داده برای جلوگیری از ازدحام در شبکه |
| Split Tunneling | تونل‌زنی تقسیم شده | هدایت بخشی از ترافیک از طریق VPN و بخشی دیگر از طریق اتصال عادی |
| Keepalive | حفظ اتصال | ارسال پیام‌های دوره‌ای برای جلوگیری از قطع اتصال |
| Cipher Suite | مجموعه رمز | ترکیبی از الگوریتم‌های رمزنگاری برای تأمین امنیت |
| Handshake | دست دادن | فرآیند برقراری اتصال اولیه |
| Perfect Forward Secrecy | محرمانگی پیش‌رو کامل | ویژگی امنیتی که حتی با افشای کلید طولانی‌مدت، داده‌های گذشته در امان می‌مانند |
| DNS Leak | نشت DNS | افشای درخواست‌های DNS خارج از تونل VPN |
| Packet Loss | اتلاف بسته | از دست رفتن بسته‌های داده در شبکه |
| DDOS | Distributed Denial of Service | حمله انکار سرویس توزیع شده |
| ISP | Internet Service Provider | ارائه‌دهنده خدمات اینترنت |

### اختصارات رایج

| اختصار | عبارت کامل |
|--------|------------|
| ACK | Acknowledgement |
| API | Application Programming Interface |
| ARP | Address Resolution Protocol |
| BGP | Border Gateway Protocol |
| DHCP | Dynamic Host Configuration Protocol |
| DNS | Domain Name System |
| FPS | First-Person Shooter |
| FPS | Frames Per Second |
| HTTP | Hypertext Transfer Protocol |
| HTTPS | HTTP Secure |
| ICMP | Internet Control Message Protocol |
| IP | Internet Protocol |
| IPv4 | Internet Protocol version 4 |
| IPv6 | Internet Protocol version 6 |
| LAN | Local Area Network |
| MAC | Media Access Control |
| MITM | Man-in-the-Middle |
| MOBA | Multiplayer Online Battle Arena |
| MMO | Massively Multiplayer Online |
| P2P | Peer-to-Peer |
| QoS | Quality of Service |
| RSA | Rivest-Shamir-Adleman |
| TCP | Transmission Control Protocol |
| UDP | User Datagram Protocol |
| URI | Uniform Resource Identifier |
| URL | Uniform Resource Locator |
| WAN | Wide Area Network |

## نمودارهای فنی

### معماری کلی QUIC VPN

```
┌───────────────────────┐                         ┌───────────────────────┐
│      کلاینت ویندوز     │                         │      سرور لینوکس      │
│                       │                         │                       │
│  ┌─────────────────┐  │                         │  ┌─────────────────┐  │
│  │   برنامه‌های     │  │                         │  │    روتینگ و     │  │
│  │    کاربر       │  │                         │  │    NAT          │  │
│  └────────┬───────┘  │                         │  └────────┬────────┘  │
│           │          │                         │           │           │
│  ┌────────┴───────┐  │                         │  ┌────────┴────────┐  │
│  │  اینترفیس TUN  │  │                         │  │  اینترفیس TUN   │  │
│  └────────┬───────┘  │                         │  └────────┬────────┘  │
│           │          │                         │           │           │
│  ┌────────┴───────┐  │      QUIC over UDP      │  ┌────────┴────────┐  │
│  │    کلاینت      │◄─┼─────────────────────────┼─►│      سرور       │  │
│  │    QUIC        │  │                         │  │      QUIC        │  │
│  └─────────────────┘  │                         │  └─────────────────┘  │
└───────────────────────┘                         └───────────────────────┘
```

### جریان داده در پروتکل QUIC

```
    ┌─────────────┐          ┌─────────────┐          ┌─────────────┐
    │  لایه برنامه  │          │  لایه برنامه  │          │  لایه برنامه  │
    └──────┬──────┘          └──────┬──────┘          └──────┬──────┘
           │                        │                        │
    ┌──────┴──────┐          ┌──────┴──────┐          ┌──────┴──────┐
    │    QUIC     │◄─Stream1─►│    QUIC     │◄─Stream1─►│    QUIC     │
    │             │◄─Stream2─►│             │◄─Stream2─►│             │
    │             │◄─Stream3─►│             │◄─Stream3─►│             │
    └──────┬──────┘          └──────┬──────┘          └──────┬──────┘
           │                        │                        │
    ┌──────┴──────┐          ┌──────┴──────┐          ┌──────┴──────┐
    │     UDP     │          │     UDP     │          │     UDP     │
    └──────┬──────┘          └──────┬──────┘          └──────┬──────┘
           │                        │                        │
    ┌──────┴──────┐          ┌──────┴──────┐          ┌──────┴──────┐
    │      IP     │          │      IP     │          │      IP     │
    └─────────────┘          └─────────────┘          └─────────────┘
     کلاینت نهایی               سرور QUIC VPN            سرور مقصد
```

### فرآیند تبادل پیام در QUIC VPN

```
کلاینت                                        سرور
  │                                             │
  │ 1. درخواست برقراری اتصال QUIC               │
  │────────────────────────────────────────────►│
  │                                             │
  │ 2. تبادل TLS (1-RTT یا 0-RTT)              │
  │◄───────────────────────────────────────────►│
  │                                             │
  │ 3. پیام ClientHello                         │
  │ (ارسال اطلاعات احراز هویت)                   │
  │────────────────────────────────────────────►│
  │                                             │
  │                                     احراز هویت کاربر
  │                                     تخصیص آدرس IP
  │                                             │
  │ 4. پیام ServerHello                         │
  │ (ارسال آدرس IP و تنظیمات)                    │
  │◄────────────────────────────────────────────│
  │                                             │
  │ راه‌اندازی اینترفیس TUN                      │
  │                                             │
  │ 5. PacketData                               │
  │ (بسته‌های IP از کلاینت به سرور)               │
  │────────────────────────────────────────────►│
  │                                             │
  │                                     مسیریابی بسته‌ها
  │                                             │
  │ 6. PacketData                               │
  │ (بسته‌های IP از سرور به کلاینت)               │
  │◄────────────────────────────────────────────│
  │                                             │
  │ 7. پیام‌های KeepAlive                        │
  │◄───────────────────────────────────────────►│
  │                                             │
  │ 8. پیام Disconnect                          │
  │ (درخواست قطع اتصال)                          │
  │────────────────────────────────────────────►│
  │                                             │
  │ 9. پیام Disconnect                          │
  │ (تأیید قطع اتصال)                            │
  │◄────────────────────────────────────────────│
  │                                             │
  │ آزادسازی منابع                              │
  │                                     آزادسازی منابع
  │                                             │
```

## کدهای نمونه

### پیاده‌سازی پایه کلاینت

این کد نمونه‌ای از پیاده‌سازی پایه یک کلاینت QUIC VPN است:

```rust
use quicvpn::client::{ClientConfig, VpnClient};
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // خواندن پیکربندی
    let config = ClientConfig {
        server_addr: "example.com:4433".parse()?,
        username: "user1".to_string(),
        password: "password123".to_string(),
        dns_servers: vec!["8.8.8.8".parse()?],
        mtu: 1400,
        auto_reconnect: true,
        gaming_optimization: true,
        ..Default::default()
    };
    
    // ایجاد کلاینت
    let mut vpn_client = VpnClient::new(config);
    
    // اتصال به سرور
    println!("درحال اتصال به سرور...");
    vpn_client.connect().await?;
    println!("اتصال برقرار شد!");
    
    // ادامه دادن تا قطع اتصال یا دریافت سیگنال توقف
    tokio::signal::ctrl_c().await?;
    
    // قطع اتصال
    println!("درحال قطع اتصال...");
    vpn_client.disconnect().await?;
    println!("اتصال قطع شد!");
    
    Ok(())
}
```

### پیاده‌سازی پایه سرور

این کد نمونه‌ای از پیاده‌سازی پایه یک سرور QUIC VPN است:

```rust
use quicvpn::server::{ServerConfig, VpnServer};
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // خواندن پیکربندی
    let config = ServerConfig {
        listen_addr: "0.0.0.0:4433".parse()?,
        cert_path: "/etc/quicvpn/server.crt".into(),
        key_path: "/etc/quicvpn/server.key".into(),
        users_file: "/etc/quicvpn/users.json".into(),
        ip_pool: "10.8.0.0/24".parse()?,
        dns_servers: vec!["8.8.8.8".parse()?],
        mtu: 1400,
        enable_game_optimization: true,
        ..Default::default()
    };
    
    // ایجاد سرور
    let mut vpn_server = VpnServer::new(config)?;
    
    // شروع سرور
    println!("درحال شروع سرور QUIC VPN...");
    vpn_server.run().await?;
    
    Ok(())
}
```

## منابع بیشتر

### کتاب‌ها و مقالات

- **"HTTP/3 Explained"** by Daniel Stenberg - کتابی در مورد HTTP/3 و QUIC
- **"The Rust Programming Language"** - کتاب رسمی زبان Rust
- **"Computer Networks: A Systems Approach"** by Larry Peterson and Bruce Davie - مرجع شبکه
- **"Understanding QUIC wire Protocol"** - مقاله Google در مورد پروتکل QUIC

### وب‌سایت‌ها و بلاگ‌ها

- [QUIC Working Group](https://quicwg.org/) - وب‌سایت رسمی گروه کاری QUIC
- [Cloudflare Learning: QUIC](https://www.cloudflare.com/learning/performance/what-is-quic/) - اطلاعات در مورد QUIC از Cloudflare
- [Rust Blog](https://blog.rust-lang.org/) - بلاگ رسمی زبان Rust
- [Mozilla Hacks: QUIC](https://hacks.mozilla.org/category/quic/) - مقالات Mozilla در مورد QUIC

### ابزارها و سایت‌های مفید

- [Wireshark](https://www.wireshark.org/) - ابزار تحلیل شبکه با پشتیبانی از QUIC
- [QUIC Tracker](https://quic-tracker.info.ucl.ac.be/) - ابزار تست تطابق پیاده‌سازی‌های QUIC
- [is-bgp.exposed](https://is-bgp.exposed/) - ابزار تست امنیت مسیریابی
- [Speedtest.net](https://www.speedtest.net/) - تست سرعت اینترنت
- [DNS Leak Test](https://www.dnsleaktest.com/) - تست نشت DNS

### جوامع و انجمن‌ها

- [Rust Users Forum](https://users.rust-lang.org/) - انجمن کاربران Rust
- [IETF QUIC Working Group Mailing List](https://mailarchive.ietf.org/arch/browse/quic/) - لیست ایمیل گروه کاری QUIC
- [Reddit r/rust](https://www.reddit.com/r/rust/) - انجمن Rust در Reddit
- [Reddit r/networking](https://www.reddit.com/r/networking/) - انجمن شبکه در Reddit

---

**یادآوری**: این مستندات در حال توسعه است و به مرور زمان به‌روزرسانی می‌شود. اگر سوال یا پیشنهادی دارید، لطفاً با تیم توسعه QUIC VPN تماس بگیرید. 