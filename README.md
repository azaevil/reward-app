# Modern & Secure Vertical Ad Reward System Engine

Bu proje; güvenli, ölçeklenebilir, reklam ağlarının kullanım politikalarını kesinlikle ihlal etmeyen ve modern editorial UI yaklaşımına sahip bir reklam & ödül yönetim altyapısıdır.

## Mimari Özellikler & Güvenlik
- **Anti-Fraud Motoru:** Redis katmanında IP ve kullanıcı bazlı Rate Limiting, Replay Attack koruması için benzersiz `impression_token` doğrulaması.
- **Sıfır Bakiye Manipülasyonu:** Mobil istemci bakiye hesaplayamaz. Tüm ödül ve hak ediş mantığı veritabanı locking (`with_for_update`) ile backend üzerinde döner.
- **KVKK/GDPR Uyumlu:** Gereksiz hassas cihaz verisi toplanmaz; yalnızca anonim davranış profilleri analiz edilir.
- **Tasarım:** Modern, editorial ve zamansız UI; neon, glassmorphism ve cyberpunk etkilerinden tamamen arındırılmıştır.

## Yerel Kurulum (Local Setup)

### Prerequisites
- Docker ve Docker Compose

### Çalıştırma Adımları

1. Repoyu klonlayın ve kök dizine geçin.
2. Servisleri Docker Compose ile başlatın:
   ```bash
   docker-compose up --build -d