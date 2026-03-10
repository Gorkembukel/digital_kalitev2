# VitrA Karo SPC Dashboard

Karo üretim hatları için gerçek zamanlı **İstatistiksel Proses Kontrolü (SPC)** dashboard uygulaması.

Flutter tabanlı masaüstü (Windows / macOS / Linux) uygulaması. Nem ve deformasyon verilerini CSV/XLSX dosyalarından okuyarak SPC grafikleri, kapasite analizleri, Nelson kural ihlalleri ve çok seviyeli alarm sistemi sunar. Yerleşik HTTP + WebSocket sunucusu ile tek cihazdan veri yayını yapılabilir; diğer cihazlar istemci modunda bağlanır.

---

## İçindekiler

- [Özellikler](#özellikler)
- [Mimari](#mimari)
- [Teknik Yığın](#teknik-yığın)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Dosya Formatları](#dosya-formatları)
- [Yapılandırma](#yapılandırma)
- [API Referansı](#api-referansı)
- [Proje Yapısı](#proje-yapısı)

---

## Özellikler

### SPC Analiz Motoru

- **I-MR Kontrol Diyagramı** — Bireysel Değer ve Hareketli Aralık grafikleri; UCL/LCL otomatik hesaplama (σ IMR yöntemi)
- **Süreç Kapasitesi** — Cp, Cpk hesaplamaları; görsel renk kodlaması (Mükemmel ≥ 1.67 / Yeterli ≥ 1.33 / Marjinal ≥ 1.00)
- **Nelson Kuralları** — 8 kural otomatik ihlal tespiti ve grafik üzerinde konumsal işaretleme
- **Risk Skoru** — 4 seviyeli alarm (Düşük / Orta / Yüksek / Kritik) tolerans dışılık oranı ve trend eğimine göre

### İzleme Modülleri

| Ekran | İçerik |
| --- | --- |
| Dashboard | Anlık KPI kartları, son alarm durumu, canlı trend |
| Nem SPC | I-MR grafiği, histogram, istatistik özeti, son ölçümler tablosu |
| Deformasyon SPC | 4 noktalı ölçüm I-MR, VitrA & EN 14411 spesifikasyon karşılaştırması |
| Kapasite | Cpk/Cp dağılım grafiği ve yeterlilik değerlendirmesi |
| Alarm Merkezi | Alarm geçmişi ve seviye filtreleme |
| Erken Uyarı | Trend projeksiyon ve risk tahmini |
| Örüntü Analizi | Nelson ihlal örüntüleri ve görsel işaretleme |
| Stratifikasyon | Vardiya / makine bazlı kırılım analizi |
| Veri Sağlığı | Veri kalitesi kontrolleri, boşluk ve sapma tespiti |
| Sunucu Yönetimi | HTTP/WS durumu, log akışı, dosya ve e-posta yapılandırması |

### Altyapı

- **Sanal Pencere (Virtual Windowing)** — Büyük dosyalar RAM'e tam yüklenmez; grafik yalnızca görünen pencereyi ± 2× tampon ile tutar, gerisi HTTP üzerinden sayfalı çekilir
- **CSV Byte-Tail** — Her broadcast döngüsünde yalnızca son okunan byte'tan sonraki yeni satırlar okunur; tüm dosya yeniden taranmaz
- **XLSX Değişim Kontrolü** — Dosya boyutu değişmemişse XLSX hiç açılmaz
- **Bloğu Olmayan Dosya I/O** — Tüm disk okuma işlemleri `Isolate.run()` ile ayrı isolate'de çalışır; UI ve HTTP sunucusu donmaz
- **E-posta Bildirimi** — SMTP üzerinden alarm e-postası; kritik / yüksek / orta seviye için ayrı ayrı açılabilir/kapatılabilir
- **Yapılandırma Kalıcılığı** — Sunucu, e-posta ve dosya ayarları Hive veritabanında saklanır

---

## Mimari

```text
┌─────────────────────────────────────────────────────────┐
│                    SUNUCU CİHAZI                        │
│                                                         │
│  ┌─────────────┐    ┌────────────────────────────────┐  │
│  │  CSV / XLSX │───▶│        SpcServerApp            │  │
│  │   Dosyaları │    │  (shelf HTTP + WebSocket)      │  │
│  └─────────────┘    │                                │  │
│                     │  ServerDataStore (RAM ≤ 1 000) │  │
│                     │  ApiHandler  /api/humidity     │  │
│                     │             /api/deformation   │  │
│                     │             /api/*/count       │  │
│                     │  WsManager  /ws                │  │
│                     └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
              │ HTTP (ilk yükleme + sayfalı fetch)
              │ WebSocket (canlı satır akışı)
              ▼
┌─────────────────────────────────────────────────────────┐
│                   İSTEMCİ CİHAZI                        │
│                                                         │
│  ConnectionProvider                                     │
│  ├─ fetchHumidityWindow(offset, limit)  ──▶ HTTP        │
│  └─ WsClientService (canlı satırlar)   ◀── WS           │
│                                                         │
│  WindowedImrChart                                       │
│  ├─ Görünen pencere: N nokta (varsayılan 300)           │
│  ├─ RAM tamponu: N × 3 nokta                            │
│  ├─ ← → sayfa gezinme + slider + CANLI butonu           │
│  └─ Tampon biterken otomatik HTTP isteği                │
└─────────────────────────────────────────────────────────┘
```

### Veri Akışı

```text
Dosya (CSV / XLSX)
    │
    ├─ İlk yükleme ──▶ Isolate.run(readCsv / readXlsx)
    │                  Son 1 000 satır RAM'e; kalan dosyada
    │
    └─ Broadcast döngüsü (Timer.periodic)
         ├─ CSV:  readNewCsvRows(byteOffset)  — yalnızca yeni byte'lar
         └─ XLSX: dosya boyutu değiştiyse readXlsx (isolate)
```

---

## Teknik Yığın

| Kategori | Paket | Sürüm |
| --- | --- | --- |
| UI Framework | Flutter | ≥ 3.24 |
| Dil | Dart SDK | ^3.5.0 |
| Grafik | fl_chart | ^0.69.0 |
| State Yönetimi | provider | ^6.1.2 |
| HTTP İstemci | http | ^1.2.2 |
| WebSocket | web_socket_channel | ^3.0.1 |
| HTTP Sunucu | shelf + shelf_router | ^1.4.2 |
| WS Sunucu | shelf_web_socket | ^2.0.0 |
| Yerel Veritabanı | hive | ^2.2.3 |
| E-posta | mailer | ^6.1.0 |
| XLSX Okuma | excel | ^4.0.0 |
| Tipografi | google_fonts | ^6.2.1 |
| Tarih/Saat | intl | ^0.19.0 |

---

## Kurulum

### Gereksinimler

- Flutter SDK ≥ 3.24 (stable kanalı)
- Dart SDK ^3.5.0 (Flutter ile birlikte gelir)
- Windows 10+ / macOS 12+ / Ubuntu 22.04+

### Adımlar

```bash
# 1. Depoyu klonla
git clone https://github.com/<kullanici>/digital_kalitev2.git
cd digital_kalitev2

# 2. Bağımlılıkları yükle
flutter pub get

# 3. Masaüstü desteğini etkinleştir (ilk kurulumda bir kez)
flutter config --enable-windows-desktop   # Windows
flutter config --enable-macos-desktop     # macOS
flutter config --enable-linux-desktop     # Linux

# 4. Çalıştır
flutter run -d windows   # veya: macos, linux
```

### Release Derlemesi

```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

Çıktı dizini:

- Windows: `build/windows/x64/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`

---

## Kullanım

### Sunucu Modu

1. Uygulamayı veri kaynağına (CSV/XLSX) erişimi olan makinede aç.
2. **Sunucu Modu**'nu seç → **Sunucu Ayarları** bölümünden:
   - Host ve port belirle (varsayılan: `0.0.0.0:8080`)
   - CSV dosyasını (nem) ve XLSX dosyasını (deformasyon) seç
   - SMTP ayarlarını yapılandır (isteğe bağlı)
3. **Sunucuyu Başlat**'a tıkla.
4. Broadcast aralığı dolduğunda sunucu dosyayı kontrol eder; yeni satır varsa tüm WebSocket istemcilerine yayınlar.

### İstemci Modu

1. Uygulamayı istemci cihazda aç.
2. **İstemci Modu**'nu seç → sunucu adresini gir (örn. `http://192.168.1.10:8080`).
3. **Bağlan**'a tıkla.
4. Menüden istenen analiz ekranına geç.

### Grafik Gezinme

I-MR grafiklerinde zaman ekseninde serbestçe gezinilebilir:

| Kontrol | Eylem |
| --- | --- |
| **←** butonu | Bir pencere geri (ör. 300 nokta öncesi) |
| **→** butonu | Bir pencere ileri |
| Kaydırma çubuğu | Tüm veri geçmişinde herhangi bir konuma atla |
| **CANLI** butonu | En son veriye dön; yeni WebSocket verisiyle otomatik güncellenir |

Nem SPC ekranında **Göster** seçeneğiyle pencere boyutu 50 / 100 / 200 / 300 nokta olarak değiştirilebilir.

---

## Dosya Formatları

### Nem Verisi — CSV

Ayırıcı otomatik tespit edilir (tab `\t`, noktalı virgül `;` veya virgül `,`).

```text
Zaman               | Nem        | Alt Tol. | Üst Tol.
2026-02-18 09:32:00 | 5.93 %rH   | 5.80     | 6.30
2026-02-18 09:33:00 | 6.01 %rH   | 5.80     | 6.30
```

| Sütun | İçerik | Notlar |
| --- | --- | --- |
| 0 | Zaman damgası | ISO 8601, `GG.AA.YYYY SS:DD` veya Excel seri sayısı |
| 1 | Nem değeri | `5.93 %rH` veya `5.93` — birim otomatik temizlenir |
| 2+ | Tolerans bilgisi | İsteğe bağlı, okunmaz |

Başlık satırları otomatik atlanır (sayısal içermeyenler).

### Deformasyon Verisi — XLSX

| Sütun | İçerik |
| --- | --- |
| A (0) | Makine adı |
| B (1) | Ürün kodu |
| C (2) | Ebat |
| D (3) | Ton / Parti |
| **E (4)** | **P1 (mm)** |
| **F (5)** | **P2 (mm)** |
| **G (6)** | **P3 (mm)** |
| **H (7)** | **P4 (mm)** |
| I (8) | VitrA tolerans |
| J (9) | EN 14411 tolerans |

İlk 2 satır başlık olarak kabul edilip atlanır. P1–P4 sütunlarından biri boşsa satır geçersiz sayılır.

---

## Yapılandırma

### Spesifikasyon Limitleri

`lib/core/constants/spec_limits.dart` dosyasından değiştirilebilir:

```dart
// Nem (%rH)
humidityLSL    = 5.80
humidityUSL    = 6.30
humidityTarget = 6.05

// Deformasyon — VitrA (mm)
deformVitraLSL = -0.7
deformVitraUSL =  1.0

// Deformasyon — EN 14411 (mm)
deformEN14411LSL = -2.0
deformEN14411USL =  2.0

// Süreç Kapasite Eşikleri (Cpk)
cpkExcellent = 1.67   // Mükemmel
cpkAdequate  = 1.33   // Yeterli
cpkMarginal  = 1.00   // Marjinal
```

### E-posta Bildirimi

Sunucu yönetimi ekranından yapılandırılır; ayarlar Hive veritabanında saklanır.

| Alan | Açıklama |
| --- | --- |
| SMTP Host | Sunucu adresi (örn. `smtp.gmail.com`) |
| Port | 587 (STARTTLS) veya 465 (SSL) |
| Kullanıcı adı / Şifre | SMTP kimlik bilgileri |
| Alıcılar | Virgülle ayrılmış e-posta listesi |
| Tetikleyiciler | Kritik / Yüksek / Orta seviye için ayrı ayrı |

> **Not:** Şifreler Hive'da şifrelenmeden saklanır. Üretim ortamında işletim sistemi anahtar kasası (Windows Credential Manager vb.) entegrasyonu önerilir.

### Performans Parametreleri

```dart
// lib/server/handlers/api_handler.dart — ServerDataStore
static const int kRamBuffer = 1000; // Dosyadan RAM'e alınan max satır

// lib/widgets/charts/windowed_imr_chart.dart
windowSize   = 300  // Grafik'te görünen nokta sayısı
bufferFactor = 3    // RAM tamponu = 300 × 3 = 900 nokta
```

---

## API Referansı

Tüm endpoint'ler `Content-Type: application/json; charset=utf-8` döner. CORS açıktır.

| Metot | Yol | Parametreler | Açıklama |
| --- | --- | --- | --- |
| GET | `/api/status` | — | Sunucu durumu, uptime, bağlı istemci sayısı |
| GET | `/api/humidity` | `limit`, `offset` | Nem verisi; `offset` verilirse dosyadan sayfalı okur |
| GET | `/api/humidity/count` | — | `{"total": N}` — toplam kayıt sayısı |
| GET | `/api/humidity/latest` | — | En son nem ölçümü |
| GET | `/api/deformation` | `limit`, `offset` | Deformasyon verisi; `offset` verilirse dosyadan sayfalı okur |
| GET | `/api/deformation/count` | — | `{"total": N}` |
| GET | `/api/deformation/latest` | — | En son deformasyon ölçümü |
| WS | `/ws` | — | Canlı veri akışı — `WsMessage` JSON frame'leri |

### Örnek: Sayfalı nem verisi

```http
GET /api/humidity?offset=1500&limit=300
```

```json
{
  "total": 6432,
  "offset": 1500,
  "count": 300,
  "data": [
    { "timestamp": "2026-02-18T09:32:00.000", "value": 5.93 }
  ]
}
```

---

## Proje Yapısı

```text
lib/
├── core/
│   ├── constants/
│   │   ├── spec_limits.dart        # Tolerans ve alarm eşikleri
│   │   └── spc_constants.dart      # d2, D3, D4, A2 SPC katsayıları
│   ├── models/
│   │   ├── measurement.dart        # HumidityMeasurement, DeformationMeasurement
│   │   ├── alarm_level.dart        # AlarmLevel enum
│   │   └── app_mode.dart           # AppMode enum (server / client)
│   ├── spc/
│   │   ├── imr_calculator.dart     # I-MR hesaplama motoru
│   │   ├── capability_calculator.dart
│   │   ├── nelson_rules.dart       # 8 Nelson kuralı denetimi
│   │   └── risk_calculator.dart    # Risk skoru ve trend analizi
│   └── theme/
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       └── app_theme.dart
│
├── server/
│   ├── database/config_database.dart  # Hive — ayar kalıcılığı
│   ├── handlers/
│   │   ├── api_handler.dart           # REST + ServerDataStore
│   │   └── ws_manager.dart            # WebSocket istemci havuzu
│   ├── models/
│   │   ├── server_config.dart
│   │   ├── email_config.dart
│   │   ├── file_config.dart
│   │   └── ws_message.dart
│   ├── services/
│   │   ├── file_reader_service.dart   # CSV/XLSX okuma + byte-tail
│   │   ├── mock_data_service.dart     # Test verisi üreteci
│   │   └── email_service.dart         # SMTP gönderimi
│   └── server_app.dart                # ChangeNotifier — sunucu yaşam döngüsü
│
├── client/
│   ├── models/connection_status.dart
│   ├── providers/connection_provider.dart  # State + windowed fetch
│   └── services/
│       ├── http_client_service.dart
│       └── ws_client_service.dart
│
├── screens/
│   ├── dashboard/
│   ├── connection/
│   ├── humidity_spc/
│   ├── deformation_spc/
│   ├── capability/
│   ├── alarm_center/
│   ├── early_warning/
│   ├── pattern_analysis/
│   ├── stratification/
│   ├── data_health/
│   └── server_mode/
│
├── widgets/
│   ├── charts/
│   │   ├── imr_chart.dart             # I-MR (fl_chart)
│   │   ├── windowed_imr_chart.dart    # Sanal pencereli I-MR
│   │   ├── histogram_chart.dart
│   │   └── chart_helpers.dart
│   ├── kpi_card.dart
│   ├── alarm_badge.dart
│   └── section_header.dart
│
├── app_navigation.dart   # NavigationRail (masaüstü) / Drawer+BottomNav (mobil)
└── main.dart
```

---



