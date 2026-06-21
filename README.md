# Tatil Maliyet Karşılaştırıcı

Yurtdışı tatil planlaması için güncel döviz kurları, uçak bileti ve otel fiyatlarını karşılaştıran web uygulaması.

## Özellikler

- **Güncel Döviz Kurları**: ECB verilerinden anlık TRY kurları (EUR, USD, GBP vb.)
- **Uçuş Arama**: Amadeus API ile gerçek zamanlı uçak bileti fiyatları
- **Otel Arama**: Şehirlerdeki otellerin güncel fiyatları ve karşılaştırması
- **Maliyet Özeti**: Seçilen uçuş + konaklama toplam maliyet hesabı (TRY cinsinden)
- **15 Popüler Destinasyon**: Barselona, Roma, Paris, Londra, Amsterdam ve daha fazlası

## Kurulum

```bash
# Bağımlılıkları yükle
npm install

# .env dosyasını oluştur
cp .env.example .env

# Uygulamayı başlat
npm start
```

Tarayıcıda `http://localhost:3000` adresini aç.

## API Anahtarı (Ücretsiz)

Uçuş ve otel araması için Amadeus API anahtarı gereklidir:

1. [developers.amadeus.com](https://developers.amadeus.com) adresine git
2. Ücretsiz hesap oluştur (Self-Service tier)
3. Bir uygulama oluştur ve API Key + Secret al
4. `.env` dosyasına ekle:

```env
AMADEUS_API_KEY=buraya_api_key
AMADEUS_API_SECRET=buraya_api_secret
```

**Not**: Self-Service tier aylık 500 ücretsiz API isteği sağlar.

## Döviz Kurları

Döviz kurları tamamen ücretsizdir ve API anahtarı gerektirmez. Birden fazla kaynak denenir:
- Frankfurter API (ECB verileri)
- Open Exchange Rates API
- ExchangeRate API

## Kullanım

1. Kalkış havalimanı kodunu gir (IST, SAW, ESB vb.)
2. Varış şehrini seç
3. Tarih aralığını belirle (varsayılan: 1 hafta)
4. Kişi ve oda sayısını ayarla
5. "Ara ve Karşılaştır" butonuna tıkla

Sonuçlarda en uygun uçuşu ve oteli seçerek toplam maliyet özetini görebilirsin.

## Teknolojiler

- **Backend**: Node.js, Express
- **Frontend**: Vanilla HTML/CSS/JS
- **API'ler**: Amadeus (uçuş/otel), Frankfurter/ECB (döviz kurları)
