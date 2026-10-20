# DapurKita

Aplikasi Flutter pencari resep untuk UTS Pemrograman Mobile. Antarmuka berbahasa Indonesia; nama, bahan, dan petunjuk resep mengikuti bahasa API (umumnya Inggris).

Nama tampilan aplikasi: **DapurKita**. Nama package/proyek Flutter: `dapurkita` (huruf kecil mengikuti aturan Dart). Identifier aplikasi: `com.example.dapurkita`.

## Fitur

- Onboarding dengan ilustrasi dari referensi, lalu beranda dengan kartu dua kolom.
- Daftar resep dinamis, pencarian nama, dan halaman detail.
- Filter kategori dari API (Chicken, Seafood, Dessert, dan kategori lainnya). Memilih kategori atau Semua menghapus pencarian sebelumnya dan memuat daftar kategori tersebut.
- Foto, kategori, negara asal, bahan, takaran, dan cara memasak.
- FutureBuilder: loading, sukses, hasil kosong, dan error dengan tombol coba lagi.
- Muat ulang dan pengganti foto saat gambar gagal dimuat.

## Teknologi dan struktur

Flutter, Dart, Material 3, serta package `http` untuk permintaan HTTP lintas platform.

- `lib/models/meal.dart`: validasi dan konversi JSON menjadi objek Dart.
- `lib/services/meal_service.dart`: HTTP, status respons, timeout, dan error.
- `lib/main.dart`: tema, onboarding, dan pintu masuk aplikasi.
- `lib/screens/`: beranda, kategori, FutureBuilder, dan detail resep.
- `lib/widgets/meal_image.dart`: foto resep dengan tampilan cadangan.
- `assets/images/onboarding.png`: referensi yang diberikan pengguna; hanya area kolase makanan ditampilkan pada onboarding.
- `test/`: pengujian model, API, dan alur antarmuka dengan HTTP mock.
- `integration_test/` dan `test_driver/`: pengujian Android dengan API asli dan tangkapan layar.

## Menjalankan

Gunakan Flutter dengan Dart >=3.13.2 dan koneksi internet.

```sh
flutter pub get
flutter run
```

Browser: `flutter run -d chrome`. Android: hubungkan perangkat dengan USB debugging atau jalankan emulator, lalu `flutter run -d <device-id>`.

```sh
flutter analyze
flutter test
flutter build apk --release
```

Uji alur di emulator/perangkat Android (ganti ID sesuai `flutter devices`):

```sh
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554
```

Tangkapan layar pengujian disimpan di `build/screenshots/`. Pengujian ini membutuhkan koneksi internet.

## Sumber data

Dokumentasi: https://www.themealdb.com/docs_api_guide.php

Endpoint: `https://www.themealdb.com/api/json/v1/1/search.php?s=chicken`. Pencarian awal memakai `s=` untuk menampilkan daftar bawaan API, bukan seluruh katalog. Respons `meals: null` berarti tidak ditemukan. Key publik `1` disediakan untuk pembelajaran/pengembangan; publikasi aplikasi memerlukan peninjauan ketentuan dan key produksi penyedia.

Kategori dimuat dari `categories.php`, daftar per kategori dari `filter.php?c=Seafood`, dan bahan/petunjuk lengkap dari `lookup.php?i=<id>`. Pencarian nama setelah memilih kategori menyaring hasil dalam kategori aktif; memilih kategori lagi menghapus pencarian. Tidak menampilkan penulis atau estimasi durasi yang tidak tersedia pada API.

Data diminta saat membuka aplikasi, mencari, atau memuat ulang. Tidak ada penyimpanan offline. Pengujian otomatis memakai mock agar tidak bergantung pada server.
