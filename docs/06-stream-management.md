# مدیریت استریم‌ها

## منطق پروتکل QUIC

پروتکل QUIC یکی از مهم‌ترین ویژگی‌های منحصر به فرد خود را با پشتیبانی از استریم‌های چندگانه (multiplexed streams) ارائه می‌دهد. این ویژگی به سیستم QUIC VPN اجازه می‌دهد تا چندین جریان داده مستقل را روی یک کانکشن واحد مدیریت کند.

### ویژگی‌های استریم در QUIC

1. **چندگانگی (Multiplexing)**: امکان ارسال چندین جریان داده مستقل روی یک کانکشن
2. **مستقل بودن استریم‌ها**: از دست رفتن بسته در یک استریم، استریم‌های دیگر را مسدود نمی‌کند
3. **کنترل جریان مستقل**: هر استریم می‌تواند کنترل جریان خاص خود را داشته باشد
4. **اولویت‌بندی**: امکان تعیین اولویت برای استریم‌های مختلف
5. **انواع استریم**:
   - استریم‌های دوطرفه (Bidirectional)
   - استریم‌های یک‌طرفه (Unidirectional)

## نحوه مدیریت استریم‌ها در کد

در پروژه QUIC VPN، استریم‌ها برای اهداف مختلفی استفاده می‌شوند. بررسی عمیق نحوه مدیریت استریم‌ها در کد به شرح زیر است:

### در سمت سرور (server/client_manager.rs)

```rust
// Open bidirectional stream for control messages
let (mut send, mut recv) = connection.open_bi().await?;
```

در سمت سرور، هنگام دریافت اتصال جدید، یک استریم دوطرفه برای تبادل پیام‌های کنترلی ایجاد می‌شود. این استریم برای موارد زیر استفاده می‌شود:

1. دریافت درخواست‌های ClientHello
2. ارسال پاسخ‌های ServerHello
3. تبادل اطلاعات احراز هویت
4. انتقال پیام‌های مدیریتی

سرور برای هر کلاینت متصل شده، این استریم کنترلی را نگه می‌دارد و از آن برای ارتباط مستمر استفاده می‌کند. همچنین، سرور این استریم را برای انتقال بسته‌های داده نیز استفاده می‌کند:

```rust
// در متد start_client_handler
while let Some((packet, dst_ip)) = packet_rx.recv().await {
    if dst_ip == client_ip {
        if let Some((ref mut send, _)) = client_streams.get_mut(&0) {
            let msg = Message::PacketData(packet);
            let data = msg.to_bytes().unwrap();
            let data_len = data.len() as u32;
            
            if let Err(e) = send.write_all(&data_len.to_be_bytes()).await {
                error!("Failed to send packet length to client {}: {}", client_ip, e);
                break;
            }
            
            if let Err(e) = send.write_all(&data).await {
                error!("Failed to send packet to client {}: {}", client_ip, e);
                break;
            }
        }
    }
}
```

### در سمت کلاینت (client/vpn_client.rs)

کلاینت با استفاده از روش متفاوتی استریم‌ها را مدیریت می‌کند:

```rust
// Open control stream
let (mut send, mut recv) = connection.open_bi().await?;
```

کلاینت مانند سرور یک استریم دوطرفه برای کنترل ایجاد می‌کند. اما برای انتقال داده، رویکرد متفاوتی دارد:

```rust
// در متد start_packet_handling
while let Some(packet) = tun_packet_rx.recv().await {
    match connection_clone.open_bi().await {
        Ok((mut send, _)) => {
            let message = Message::PacketData(packet);
            if let Err(e) = send_message_raw(&mut send, &message).await {
                error!("Failed to send packet to server: {}", e);
            }
        }
        Err(e) => {
            error!("Failed to open stream: {}", e);
            break;
        }
    }
}
```

کلاینت برای هر بسته داده، یک استریم جدید باز می‌کند. این رویکرد چند مشکل دارد:
1. سربار زیاد برای باز کردن استریم‌های متعدد
2. استفاده ناکارآمد از منابع QUIC
3. محدودیت تعداد استریم‌های همزمان

## تحلیل و بررسی منطق استریم در کد فعلی

### مشکلات شناسایی شده

1. **عدم تطابق در رویکرد کلاینت و سرور**:
   - سرور: استفاده از یک استریم مشترک برای همه داده‌ها
   - کلاینت: ایجاد استریم جدید برای هر بسته

2. **کارایی پایین در سمت کلاینت**:
   - باز کردن مداوم استریم‌های جدید می‌تواند سربار قابل توجهی ایجاد کند
   - مصرف بالای منابع برای مدیریت استریم‌های متعدد

3. **شکست مدیریت استریم در حالت‌های استثنایی**:
   - عدم مدیریت صحیح منابع در صورت وقوع خطا
   - احتمال نشت منابع در شرایط خاص

## بهینه‌سازی‌های استریم

### 1. استفاده از استریم‌های دائمی (Persistent Streams)

به جای ایجاد استریم جدید برای هر بسته، می‌توان از استریم‌های دائمی استفاده کرد:

```rust
// ایجاد استریم داده دائمی
let (data_send, data_recv) = connection.open_bi().await?;
let data_stream = Arc::new(Mutex::new(data_send));

// استفاده از استریم داده
let data_stream_clone = data_stream.clone();
while let Some(packet) = tun_packet_rx.recv().await {
    let mut stream = data_stream_clone.lock().await;
    if let Err(e) = send_message_raw(&mut *stream, &Message::PacketData(packet)).await {
        error!("Failed to send packet: {}", e);
    }
}
```

### 2. مدیریت پول استریم (Stream Pool)

ایجاد یک پول از استریم‌ها که می‌توانند بازیافت و مجدداً استفاده شوند:

```rust
struct StreamPool {
    streams: Vec<SendStream>,
    in_use: HashSet<usize>,
}

impl StreamPool {
    async fn get_stream(&mut self, connection: &Connection) -> Result<(usize, &mut SendStream)> {
        if let Some(idx) = self.find_available() {
            self.in_use.insert(idx);
            return Ok((idx, &mut self.streams[idx]));
        }

        // ایجاد استریم جدید اگر استریم موجود نباشد
        let (send, _) = connection.open_bi().await?;
        let idx = self.streams.len();
        self.streams.push(send);
        self.in_use.insert(idx);
        Ok((idx, self.streams.last_mut().unwrap()))
    }

    fn release_stream(&mut self, idx: usize) {
        self.in_use.remove(&idx);
    }

    fn find_available(&self) -> Option<usize> {
        for i in 0..self.streams.len() {
            if !self.in_use.contains(&i) {
                return Some(i);
            }
        }
        None
    }
}
```

### 3. استفاده از استریم‌های اختصاصی برای انواع مختلف ترافیک

می‌توان استریم‌های مختلف را برای اهداف مختلف اختصاص داد:

```rust
enum StreamType {
    Control,
    Data,
    KeepAlive,
    Stats,
}

// اختصاص استریم‌های مختلف برای انواع ترافیک
let mut streams = HashMap::new();
streams.insert(StreamType::Control, connection.open_bi().await?);
streams.insert(StreamType::Data, connection.open_bi().await?);
streams.insert(StreamType::KeepAlive, connection.open_bi().await?);
streams.insert(StreamType::Stats, connection.open_bi().await?);
```

### 4. پیشنهاد اصلاحات کد

برای بهبود وضعیت فعلی، پیشنهاد می‌شود تغییراتی در فایل `client/vpn_client.rs` اعمال شود:

```rust
// اصلاح متد start_packet_handling
async fn start_packet_handling(
    &self,
    connection: Connection,
    tun_device: Arc<TunDevice>,
    control_send: SendStream,
    control_recv: RecvStream,
    mut disconnect_rx: oneshot::Receiver<()>,
) -> Result<()> {
    // ایجاد یک استریم دائمی برای انتقال داده‌ها
    let (data_send, _) = connection.open_bi().await?;
    let data_stream = Arc::new(Mutex::new(data_send));
    
    let (tun_packet_tx, mut tun_packet_rx) = mpsc::channel(1000);
    
    // Start reading from TUN device
    let tun_read_handle = tun_device.start_reading(tun_packet_tx)?;
    
    // Start task to forward packets from TUN to server
    let connection_clone = connection.clone();
    let data_stream_clone = data_stream.clone();
    let tun_to_server = tokio::spawn(async move {
        while let Some(packet) = tun_packet_rx.recv().await {
            let mut stream = data_stream_clone.lock().await;
            let message = Message::PacketData(packet);
            if let Err(e) = send_message_raw(&mut *stream, &message).await {
                error!("Failed to send packet to server: {}", e);
                // ممکن است نیاز به ایجاد استریم جدید باشد اگر استریم فعلی با خطا مواجه شده
                if let Ok((new_send, _)) = connection_clone.open_bi().await {
                    *stream = new_send;
                } else {
                    break;
                }
            }
        }
    });
    
    // باقی کد
    // ...
}
```

## عیب‌یابی مشکلات استریم

### مشکل: استریم‌های زیادی ایجاد می‌شوند

**علائم**:
- استفاده بالا از CPU و حافظه
- کندی انتقال داده
- پیام‌های خطا مربوط به محدودیت استریم

**راه حل**:
- بررسی کد برای شناسایی محل ایجاد استریم‌های جدید
- پیاده‌سازی یکی از روش‌های بهینه‌سازی مذکور
- تنظیم حداکثر تعداد استریم‌های همزمان در تنظیمات QUIC
- استفاده از ابزار پروفایلینگ برای شناسایی تعداد و عمر استریم‌ها

### مشکل: انتقال داده متوقف می‌شود

**علائم**:
- توقف ناگهانی انتقال داده
- فقدان پیام خطای واضح
- عدم دریافت اطلاعات در سمت مقابل

**راه حل**:
- بررسی وضعیت استریم‌ها و اطمینان از باز بودن آنها
- اضافه کردن مکانیزم بازیابی خودکار استریم‌ها در صورت بروز خطا
- افزودن سیستم‌ احیای اتصال (connection recovery)
- بررسی محدودیت‌های flow control در تنظیمات QUIC

### مشکل: تأخیر زیاد در انتقال داده

**علائم**:
- افزایش تأخیر در انتقال داده
- تأخیر زیاد حتی برای بسته‌های کوچک

**راه حل**:
- کاهش تعداد استریم‌های جدید
- تنظیم اولویت استریم‌ها برای ترافیک حساس به تأخیر
- بررسی تنظیمات congestion control
- بهینه‌سازی سایز بسته‌ها برای انتقال بهینه

### مشکل: استفاده نادرست از استریم‌های QUIC

**علائم**:
- خطاهای مرتبط با استریم در لاگ‌ها
- مصرف غیرعادی منابع

**راه حل**:
- بررسی کد برای اطمینان از استفاده صحیح از API استریم‌ها
- بررسی نحوه خواندن و نوشتن داده روی استریم‌ها
- اطمینان از بسته شدن مناسب استریم‌ها پس از استفاده
- بررسی توالی عملیات خواندن و نوشتن در استریم‌ها

## نکات پیشرفته مدیریت استریم

### 1. کنترل جریان (Flow Control)

QUIC دارای مکانیزم کنترل جریان در سطح استریم و کانکشن است:

```rust
// تنظیم flow control در تنظیمات QUIC
let mut transport_config = quinn::TransportConfig::default();
transport_config.stream_receive_window(1_000_000); // تنظیم پنجره دریافت استریم
transport_config.receive_window(10_000_000);     // تنظیم پنجره دریافت کانکشن
```

### 2. اولویت‌بندی استریم‌ها

برای بهبود عملکرد گیمینگ، می‌توان استریم‌ها را اولویت‌بندی کرد:

```rust
// پیاده‌سازی اولویت‌بندی ساده برای استریم‌ها
enum StreamPriority {
    High,   // برای داده‌های حساس به تأخیر
    Medium, // برای داده‌های معمولی
    Low,    // برای داده‌های پس‌زمینه
}

// استفاده از استریم‌های مختلف برای سطوح مختلف اولویت
let high_priority_stream = connection.open_bi().await?;
let medium_priority_stream = connection.open_bi().await?;
let low_priority_stream = connection.open_bi().await?;

// انتخاب استریم براساس اولویت داده
fn select_stream_for_packet(
    packet: &[u8], 
    high: &mut SendStream, 
    medium: &mut SendStream, 
    low: &mut SendStream
) -> &mut SendStream {
    if is_high_priority_packet(packet) {
        high
    } else if is_medium_priority_packet(packet) {
        medium
    } else {
        low
    }
}
```

### 3. مدیریت خطا و بازیابی

مدیریت مناسب خطا برای استریم‌ها بسیار مهم است:

```rust
// نمونه کد برای مدیریت خطای استریم با قابلیت بازیابی
async fn send_with_retry(
    connection: &Connection,
    stream: &mut Option<SendStream>,
    message: &Message,
    max_retries: usize,
) -> Result<()> {
    let mut retries = 0;
    
    loop {
        if stream.is_none() {
            *stream = Some(connection.open_uni().await?);
        }
        
        match send_message_raw(stream.as_mut().unwrap(), message).await {
            Ok(_) => return Ok(()),
            Err(e) => {
                retries += 1;
                if retries >= max_retries {
                    return Err(e.into());
                }
                
                // استریم را بازنشانی کنید
                *stream = None;
                tokio::time::sleep(Duration::from_millis(10)).await;
            }
        }
    }
}
``` 