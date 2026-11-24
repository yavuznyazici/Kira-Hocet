# Kira Hoçet

Flutter ile geliştirilmiş, Türkçe ve çevrimdışı çalışan kira takip uygulaması.

## İlk sürüm özellikleri
- Daire ve kiracı bilgilerini ekleme, düzenleme ve silme
- Aylık kira tutarı ve ödeme gününü takip etme
- Her daire/ay için ödeme işaretleme ve geri alma
- Zamlı kira tutarını seçilen ay/yıldan itibaren uygulama
- Zam dönemi yaklaşınca uyarı ve tutar girilmemişse `TUTAR GİR` gösterimi
- Aylık toplam, tahsil edilen ve kalan kira özeti
- Yatay kaydırılabilir ay tablosu (önceki ay, mevcut ay ve sonraki ay görünümü)
- Zam hesaplayıcısı ve temel istatistikler
- Yazı boyutu, satır yüksekliği ve ay sütunu genişliği ayarları
- Veriler cihazda SQLite veritabanında saklanır; internet gerekmez.

## Gereksinimler
- Flutter stable
- Android SDK

## Çalıştırma
```bash
flutter pub get
flutter run
```

## APK oluşturma
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

## Android proje klasörü
Bu kaynak paketi Flutter uygulama kaynaklarını ve GitHub Actions iş akışını içerir. İlk yerel çalıştırmada platform dosyalarını oluşturmak için:
```bash
flutter create --platforms=android .
```
Ardından:
```bash
flutter pub get
flutter run
```

## GitHub Actions
`.github/workflows/android-apk.yml` her push'ta Android release APK üretir ve Actions artifact olarak saklar.

## Veri güvenliği
İlk sürümde veriler yalnızca uygulamanın kurulu olduğu cihazda tutulur. Uygulamayı silmek veya cihazı sıfırlamak yerel verileri silebilir. Düzenli cihaz yedeği alınması önerilir. Bulut senkronizasyonu bu sürümde yoktur.
