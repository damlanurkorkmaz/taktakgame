# Tak Tak!

Tek dokunuşla oynanan bir çivi çakma oyunu. Göstergedeki ibre yeşil bölgedeyken ekrana dokun, çekiç insin, çivi tek seferde gömülsün.

## Nasıl oynanır

Bant sürekli akar, üstündeki çiviler çekicin altından geçer. Çivi sarı okun üstüne geldiği anda ekrana dokun. Puan, vuruşun ne kadar tam olduğuna bağlıdır:

- **Mükemmel (tam ortada):** Çivi tek vuruşta gömülür, 3 puan × çarpan. Üst üste her 5 mükemmel vuruşta çarpan artar (en fazla x5).
- **İyi (biraz kaymış):** Çivi yarıya girer, 2 puan, seri sıfırlanır. İkinci vuruşla tamamlanabilir.
- **Eğri (kenardan):** Çivi eğri girer, 1 puan, seri sıfırlanır.
- **Kaçtı:** Hiç vurulmadan geçen çivi bir can götürür. Vurulup yarım kalan çivi cezasız geçer.
- **Boş vuruş:** Altında çivi yokken vurursan can gitmez ama seri bozulur.
- 3 can var, bitince oyun biter. Oyun başına bir kez bir can alıp devam edebilirsin.
- **Hız:** Bant yavaş başlar, iyi vuruşlarla hızlanır, can kaybedince biraz yavaşlar. Ayrıca birkaç saniyede bir tempo kademeli olarak değişir: sakin, normal ya da hızlı ("HIZLANIYOR!").
- **Zorlu çivi** (kalın, koyu, turuncu çizgili): iki mükemmel vuruş ister; gömülünce +5 puan bonus.
- **Altın çivi:** gömülünce +5 para.
- **Kırmızı çivi:** vurma! Vurursan bir can gider; bırak bant götürsün.
- İlerledikçe birbirine çok yakın gelen çift çiviler de çıkar.

## Seviyeler

İlk bölüm ("Atölye") 30 seviyedir. Her seviyenin bir hedefi vardır: *25 çivi çak*, *12 mükemmel vuruş*, *4 zorlu çivi göm* gibi.

- **Yıldızlar:** Bitirmek 1 yıldız; %70 isabet 2 yıldız; %90 isabet ya da 10'luk seri 3 yıldız.
- **Sandık:** Her 15 yıldızda bir sandık açılır (200 para, bazen bir çekiç).
- **Patron seviyeleri:** Her 5. seviye; daha hızlı bant, karışık çiviler, daha büyük ödül.
- **Kademeli yenilikler:** 3. seviyede altın çivi, 6'da zorlu çivi, 8'de çift çiviler, 13'te kırmızı çivi (vurma!), 16'da hız dalgaları. Her yenilik ilk çıktığında bir tanıtım kartı gösterilir.
- **Sonsuz mod:** 10. seviye geçilince açılır; rekor (ve Kristal çekiç) buradan gelir.

Seviyeler `TakTak/Model/Level.swift` içinde kurallarla üretilir (hedef, hız, çivi karışımı). Yıldız eşikleri ve ödüller de aynı dosyada.

## Günlük görevler

Her gün oyuncunun ilerlemesine uygun 3 görev çıkar (ör. *40 mükemmel vuruş yap*, *Bir patron seviyesi geç*, *Tek oyunda 15'lik seri yap*). Görevler gece yarısı yenilenir.

- Biten görevin ödülü (para ya da yıldız) Görevler ekranından alınır; oyun sırasında görev bitince üstte "GÖREV TAMAM!" kartı çıkar.
- Bitmemiş bir görev günde bir kez başka bir görevle değiştirilebilir.
- Üç görevin ödülü de alınınca **görev sandığı** açılır: 250 para, 3 yıldız, %30 ihtimalle bir çekiç.
- **Görev serisi:** Sandığı her gün açan oyuncunun ödülü her gün %10 artar (en fazla 2 kat); bir gün atlanırsa seri sıfırlanır.

Görev türleri, hedefler ve ödüller `TakTak/Model/Quest.swift` içinde.

## Çekiçler, güçlendiriciler, özel çiviler

- **Çekiç güçleri:** Lastik Tokmak (iyi bölgesi %20 geniş), Balyoz (zorlu çivi tek vuruş), Altın Çekiç (çivi başına +1 para), Neon (seri her 3 mükemmelde artar), Kristal (mükemmel bölgesi %30 geniş). Ayarlar `HammerVariant.swift` içinde.
- **Güçlendiriciler:** Geniş bölge (8 sn), Yavaş çekim (5 sn), +1 Can. Oyun içinde alttaki butonlarla kullanılır, seviyeden önce seçilebilir (geniş bölge ilk 10 sn, +1 can ile 4 canla başlama), mağazadan parayla alınır, bantta arada çıkan baloncuk vurulunca kazanılır.
- **Özel çiviler (seviye 20+):** Metal levha (yalnızca mükemmel), yaylı (geri zıplar), buz (kayar), bomba (tam vurunca yanındakileri gömer, kenardan vurunca can gider).

## Gelir ve sosyal: App Store öncesi yapılacaklar

Kod hazır, ama aşağıdaki hesap ayarları senin tarafında yapılmalı:

1. **AdMob (ödüllü reklam)**
   - admob.google.com'da uygulamayı ekle, bir **Ödüllü (Rewarded)** reklam birimi oluştur.
   - Gerçek kimlikler eklendi: uygulama kimliği `TakTak-Info.plist` > `GADApplicationIdentifier`,
     ödüllü reklam birimi `TakTak/Services/AdsManager.swift` > `liveRewardedUnitID`.
   - Debug ve TestFlight derlemelerinde otomatik olarak Google'ın **test** reklamı gösterilir;
     gerçek reklamlar yalnızca App Store sürümünde çıkar (kendi reklamına tıklamak hesabı askıya aldırabilir).
   - Reklamlar iki yerde: "Reklam izle, bir can al" (oyun sonu) ve görev sandığında "parayı 2 katına çıkar".
2. **Uygulama içi satın almalar** (App Store Connect > Uygulama İçi Satın Almalar; önce *Ücretli Uygulamalar* sözleşmesi imzalanmalı)
   - `com.damlanur.taktakgame.noads` — Tüketilemez: Reklamsız (ödüller reklam izlemeden verilir)
   - `com.damlanur.taktakgame.coins1000`, `coins3000`, `coins8000` — Tüketilebilir para paketleri
3. **Game Center:** App Store Connect > Game Center'da `taktak_endless` kimlikli bir sıralama oluştur (yüksek skor iyi). Sonsuz mod rekoru oraya gönderilir; menüdeki kupa butonu sıralamayı açar.
4. **Uygulama gizliliği:** AdMob eklendiği için App Store Connect'teki *Uygulama Gizliliği* bölümünü güncelle (cihaz kimliği, kullanım verisi, reklam verisi; "üçüncü taraf reklam" amaçlı). Gizlilik politikası sayfası da reklamdan bahsetmeli.
5. **Kod imzalama:** Projede Game Center yetkisi (`TakTak.entitlements`) var. İmzalama hatası alırsan Apple Developer > Identifiers'da uygulamanın Game Center yeteneğinin açık olduğunu kontrol edip profili yeniden oluştur.

## Cila

- **Müzik:** `TakTak/Audio/workshop_loop.wav`, 100 BPM, 19,2 sn kesintisiz döngü (kodla üretildi). Ayarlar'dan kapatılabilir; başka bir uygulamada müzik çalıyorsa başlamaz.
- **İlk açılış eğitimi:** 1. seviyeden önce 3 adımlık kart, ilk oyunda bant yavaş ve çivi yerindeyken "ŞİMDİ DOKUN!" yardımı.
- **Rekor kartı:** Sonsuz modda rekor kırınca 1080x1350 boyutunda paylaşılabilir bir görsel oluşur.

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

Zorluk ayarları `TakTak/Game/GameScene.swift` içindeki `Tuning` bölümündedir: bant hızı ve hızlanma, vuruş pencereleri, çivi aralıkları, zorlu/altın/çift çivi olasılıkları, puanlar. Günlük ödül miktarları `GameStore.dailyRewards`, çekiç fiyatları ise `HammerVariant.price` içindedir.

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

## Lisanslar

Fontlar SIL Open Font License 1.1 ile dağıtılır, ayrıntılar `Licenses/` klasöründe.

## Destek ve gizlilik sayfaları

`docs/` klasörü GitHub Pages ile yayınlanır (Settings > Pages > Branch: `main`, klasör: `/docs`).

- Destek: https://damlanurkorkmaz.github.io/taktakgame/support.html
- Gizlilik: https://damlanurkorkmaz.github.io/taktakgame/privacy.html

Sayfalar Türkçe ve İngilizcedir; `?lang=tr` / `?lang=en` ile dil seçilebilir.

## Dil desteği

Uygulama Türkçe ve İngilizcedir. Metinler kodda `L("Türkçe", "English")` ile yazılır
(`TakTak/Model/Lang.swift`). Cihaz dili Türkçe ise Türkçe, değilse İngilizce açılır.
