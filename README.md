# Tak Tak!

Tek dokunuşla oynanan bir çivi çakma oyunu. Göstergedeki ibre yeşil bölgedeyken ekrana dokun, çekiç insin, çivi tek seferde gömülsün.

## Nasıl oynanır

- **Yeşil bölge (mükemmel):** Çivi tek vuruşta gömülür. Arka arkaya mükemmel vuruşlar seriyi ve puan çarpanını artırır (x2, x3 … x5).
- **Kahverengi bölge (iyi):** Çivi yarıya kadar girer, ikinci bir vuruş gerekir. Seri sıfırlanır.
- **Dışarısı:** Çivi eğilir ve oyun biter.
- **Altın çivi:** Arada çıkar, çakınca bonus para verir.
- Her çividen sonra bant kayar, ibre hızlanır ve bölgeler daralır.

## Özellikler

- SpriteKit oyun ekranı: çekiç sallanması, kıvılcımlar, ekran sarsıntısı, titreşim ve kodla üretilmiş sesler
- SwiftUI ekranları: ana menü, oyun sonu, mağaza (6 çekiç), günlük ödül (7 günlük seri), ayarlar
- Kalıcı veriler (`UserDefaults`): para, rekor, sahip olunan ve seçili çekiç, günlük seri, ses ve titreşim ayarları
- Tüm görseller (çekiçler, çiviler, bant) Core Graphics ile vektör olarak çizilir, görsel dosyası gerekmez

## Kurulum

1. Xcode 16 veya üstü gerekir. Minimum iOS sürümü 17.0, uygulama yalnızca iPhone'da dikey çalışır.
2. `TakTak.xcodeproj` dosyasını aç.
3. **TakTak** hedefinde *Signing & Capabilities* sekmesinden kendi **Team**'ini seç. Bundle ID'yi (`com.damlanur.taktakgame`) değiştirmen gerekebilir.
4. Bir iPhone simülatörü ya da kendi telefonunu seçip ▶ ile çalıştır.

Proje Xcode 16'nın klasör senkronizasyonunu kullanır: `TakTak/` içine eklenen her dosya otomatik olarak projeye dahil olur.

## Proje yapısı

```
TakTak/
  App/        Uygulama girişi ve ekranlar arası geçiş
  Model/      GameStore (kalıcı veriler), çekiç kataloğu
  Art/        Renkler, fontlar ve çizimler (çekiç, çivi, bant)
  Game/       GameScene (oyun döngüsü), titreşim, ses
  Views/      SwiftUI ekranları
  Fonts/      Baloo 2 ve Nunito (SIL Open Font License, bkz. Licenses/)
```

## Oyun dengesi

Zorluk ayarları `TakTak/Game/GameScene.swift` içindeki `Tuning` bölümündedir: ibre hızı, bölge genişlikleri, altın çivi olasılığı. Günlük ödül miktarları `GameStore.dailyRewards`, çekiç fiyatları ise `HammerVariant.price` içindedir.

## Codemagic ile App Store'a gönderme

Depoda hazır bir `codemagic.yaml` var. İlk derlemeden önce:

1. Apple Developer hesabında bundle ID'yi kaydet: `com.damlanur.taktakgame` (değiştirirsen hem projede hem `codemagic.yaml`'da değiştir).
2. App Store Connect'te uygulama kaydını oluştur. *Genel Bilgiler*'deki **Apple ID** numarasını `codemagic.yaml`'daki `APP_STORE_APPLE_ID`'ye yaz.
3. App Store Connect > Kullanıcılar ve Erişim > Entegrasyonlar'dan bir API anahtarı (App Manager rolü) oluştur. Codemagic > Team integrations > Developer Portal'a ekle. Verdiğin adı `codemagic.yaml`'daki `app_store_connect:` satırına yaz.
4. Codemagic > Code signing identities'e bir Apple Distribution sertifikası ekle (ya da Codemagic'e oluşturt).
5. Derlemeyi başlat. Başarılı derleme TestFlight'a yüklenir; telefonda deneyip App Store'a elle gönder.

App Store Connect'te ayrıca şunlar gerekir:

- **Gizlilik politikası URL'si** (her uygulama için zorunlu). Uygulama hiçbir veri toplamıyor, kısa bir sayfa yeterli.
- **Uygulama gizliliği:** "Veri toplanmıyor" (Data Not Collected).
- **Yaş derecelendirmesi** anketi (şiddet vb. yok, 4+ çıkar).
- **Ekran görüntüleri:** 6.9" iPhone (ör. iPhone 16 Pro Max simülatörü) için en az bir set.

## Sonraki sürümler için fikirler

- Ödüllü reklam: "Devam et" hakkını reklamla vermek (AdMob vb. eklenince App Privacy bilgileri ve izin metni güncellenmeli)
- Reklamsız satın alma (StoreKit 2)
- Game Center sıralaması
- Tahta ve çivi temaları

## Lisanslar

Fontlar SIL Open Font License 1.1 ile dağıtılır, ayrıntılar `Licenses/` klasöründe.
