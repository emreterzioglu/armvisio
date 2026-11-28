# Robot - Kamera PC haberlesme protokolu (TCP)

| Konu | Deger |
|---|---|
| Baglanti | TCP/IP, duz metin (ASCII) |
| Sunucu (dinleyen) | ROBOT, IP `192.168.212.30`, port `5000` |
| Istemci (baglanan) | Kamera PC'si (ornek IP `192.168.212.10`, maske `255.255.255.0`) |
| Mesaj sonu | Her mesaj `;` ile biter (satir sonu yok) |
| Yon | Sadece robot -> PC. Robot cevap BEKLEMEZ (hareket durmasin diye). |

## Akis (her cevrim)
1. Robot 5000 portunu acar, PC'nin baglanmasini en fazla 60 s bekler.
2. PC `192.168.212.30:5000` adresine baglanir.
3. Robot hareket ederken her foto noktasinin tam ustunden gecerken gonderir:
   `KONUM10;` `KONUM11;` `KONUM12;` `KONUM7;` `KONUM6;` ... `KONUM1;` `KONUM8;` `KONUM9;`
   (sayi = robot noktasi pFoto numarasi; 12 mesaj, yaklasik 0.33 s arayla)
4. PC her `KONUMn;` mesajinda HEMEN fotograf ceker (gecikme ne kadar azsa aci o kadar dogru).
5. Cevrim sonunda robot `BITTI;` gonderir ve baglantiyi kapatir.
6. Bir sonraki cevrimde PC yeniden baglanir.

## pFoto numarasi -> tup etrafindaki aci
| pFoto | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Aci | 0 | -30 | -60 | -90 | -120 | -150 | -180 | +30 | +60 | +90 | +120 | +150 |

## PC tarafi icin notlar
- Mesajlar TCP akisinda birlesik gelebilir (ornek `KONUM6;KONUM5;`): `;` ile bolunmeli.
- Robot cevap beklemez; PC cevap gondermek isterse robot okumaz.
- Robota ulasilamiyorsa (robot henuz dinlemiyorsa) PC ~1 s arayla yeniden denemeli.
