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
3. **TakTak** hedefinde *Signing & Capabilities* sekmesinden kendi **Team**'ini seç. Bundle ID'yi (`com.damlanurkorkmaz.taktak`) değiştirmen gerekebilir.
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

## Yapılacaklar (App Store öncesi)

- [ ] **Ödüllü reklam:** "Reklam izle, devam et" butonu şu an doğrudan devam ettiriyor. `GameView.swift` içindeki `TODO` noktasına bir reklam SDK'sı (ör. Google AdMob) bağlanmalı.
- [ ] **Reklamsız satın alma:** Mağazadaki "Reklamları kaldır" butonuna StoreKit 2 ile uygulama içi satın alma eklenmeli.
- [ ] **Sıralama:** Game Center liderlik tablosu.
- [ ] Tahta ve çivi temaları (mağazadaki "Yakında" sekmeleri).
- [ ] App Store Connect: ekran görüntüleri, açıklama, gizlilik bilgileri (reklam SDK'sı eklenince gerekecek).

## Lisanslar

Fontlar SIL Open Font License 1.1 ile dağıtılır, ayrıntılar `Licenses/` klasöründe.
