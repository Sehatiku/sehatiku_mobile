# Mobile Push Notification — Implementation Guide (Patient App)

> Panduan untuk tim mobile mengintegrasikan push notification (pop-up sistem) di
> Patient App, berdasarkan backend yang sudah dibangun (`internal/gateway/push`,
> `internal/usecase/device_push_token_usecase.go`, `internal/usecase/push_usecase.go`).
> Backend memakai Firebase Cloud Messaging (FCM) — mobile **harus** pakai Firebase SDK
> resmi (Android/iOS/Flutter/React Native, sesuaikan stack app kalian).
>
> Endpoint terkait sudah didaftar lengkap di `docs/api_contract.md` (`POST` /
> `DELETE /api/v1/patients/device-tokens`). Dokumen ini fokus ke **alur integrasi**
> dari sisi app, bukan mengulang kontrak API.

---

## 1. Alur Besar

```
App start / login
   │
   ▼
Firebase SDK generate FCM token
   │
   ▼
POST /api/v1/patients/device-tokens   ──▶  backend simpan ke tabel device_push_tokens
   │
   ▼
(kapan pun ada event: eskalasi risiko / balasan konsultasi dokter)
   │
   ▼
Backend kirim FCM multicast ke semua token aktif pasien
   │
   ▼
OS render pop-up notification ──▶ user tap ──▶ app buka layar sesuai `data.type`
   │
   ▼
Logout ──▶ DELETE /api/v1/patients/device-tokens (nonaktifkan token device ini)
```

---

## 2. Setup Firebase di App

1. Buat/pakai project Firebase yang sama dengan yang dipakai backend (service-account
   JSON di `FIREBASE_CREDENTIALS_JSON`/`FIREBASE_CREDENTIALS_FILE` — lihat
   `.env.example`). Backend dan app **harus** satu project Firebase yang sama, kalau
   beda project token FCM tidak akan valid untuk dikirimi pesan dari backend.
2. Android: daftarkan app di Firebase Console, download `google-services.json`,
   pasang Firebase Messaging SDK sesuai platform (native Kotlin/Java, atau
   `firebase_messaging` kalau Flutter, atau `@react-native-firebase/messaging` kalau
   React Native — pakai plugin resmi, jangan reimplement FCM protocol sendiri).
3. iOS: daftarkan app (bundle ID), download `GoogleService-Info.plist`, upload APNs
   Auth Key ke Firebase Console (FCM meneruskan ke APNs di belakang layar — **wajib**
   untuk push iOS berfungsi).
4. Minta izin notifikasi ke user (iOS wajib eksplisit lewat
   `requestPermission`/`UNUserNotificationCenter`; Android 13+ juga butuh runtime
   permission `POST_NOTIFICATIONS`).

---

## 3. Registrasi Token ke Backend

Kapan memanggil `POST /api/v1/patients/device-tokens`:

- **Setelah login berhasil** (access token pasien sudah ada) — ambil token FCM dari
  SDK, langsung kirim ke backend.
- **Setiap kali Firebase mengeluarkan token baru** (`onTokenRefresh` /
  `onNewToken` / listener `onMessage`-nya masing-masing platform). FCM token bisa
  berubah kapan saja (reinstall app, restore, ganti device) — app **wajib** listen
  event ini seumur hidup app berjalan, bukan cuma sekali saat login.

```
POST /api/v1/patients/device-tokens
Authorization: Bearer <patient_access_token>

{
  "token": "<fcm_registration_token>",
  "platform": "android" | "ios"
}
```

Catatan penting dari implementasi backend:

- Endpoint ini **upsert by token** — aman dipanggil berkali-kali dengan token yang
  sama, tidak akan membuat baris duplikat.
- `patient_id` diambil dari JWT access token, bukan dikirim di body — pastikan
  panggilan ini terjadi **setelah** login (access token tersedia), bukan sebelum.
- Backend mendukung multi-device: satu pasien boleh login di beberapa HP sekaligus,
  semua device terdaftar akan menerima push yang sama.

---

## 4. Deregistrasi Token Saat Logout

Panggil sebelum/saat proses logout, **selagi access token masih valid**:

```
DELETE /api/v1/patients/device-tokens
Authorization: Bearer <patient_access_token>

{ "token": "<fcm_registration_token>" }
```

Idempoten — token yang sudah tidak ada/bukan milik pasien ini tetap 200, jadi app
tidak perlu logic error-handling khusus di jalur logout. Kalau ini tidak dipanggil,
device lama tetap menerima push meski user sudah logout dari app — jangan skip
langkah ini di flow logout.

---

## 5. Handle Notifikasi Masuk

Payload FCM yang dikirim backend selalu berbentuk `notification` (title + body,
untuk pop-up sistem) + `data` (custom key-value, untuk routing di app). Dua jenis
event yang sudah aktif dari backend:

| `data.type` | Trigger | `data` tambahan | Contoh title/body |
|---|---|---|---|
| `escalation` | Skor risiko pasien masuk kategori `bahaya`/`waswas` (eskalasi) | `escalation_id` | "Kondisi Anda perlu perhatian" / "Tim kesehatan Anda telah diberi tahu. Mohon segera hubungi faskes Anda." |
| `consultation_reply` | Dokter membalas konsultasi pasien | `consultation_id` | "Balasan dari dokter" / isi balasan dokter |

App perlu:

1. **Foreground**: SDK tidak otomatis menampilkan system tray notification saat app
   di foreground (perilaku standar FCM di kedua platform) — app harus render local
   notification sendiri atau tampilkan in-app banner memakai `notification.title`/
   `notification.body` dari payload yang diterima di listener foreground.
2. **Background/terminated**: OS otomatis menampilkan pop-up dari field
   `notification`. Saat user tap, app menerima `data` payload di handler
   "notification opened/tapped" — route berdasarkan `data.type`:
   - `escalation` → buka layar detail kondisi/eskalasi pasien.
   - `consultation_reply` → buka layar konsultasi (`consultation_id`).
3. Karena `data.type` baru ada 2 nilai sekarang, tangani nilai tak dikenal dengan
   fallback aman (mis. buka home), supaya kalau backend menambah tipe baru nanti,
   app lama tidak crash.

---

## 6. Yang TIDAK Perlu Dibangun di App

- **Retry/queue pengiriman** — sepenuhnya tanggung jawab backend (`PushUseCase`,
  best-effort, fire-and-forget). App hanya menerima.
- **Validasi token FCM** — kalau backend mendapati token invalid/unregistered saat
  kirim, backend otomatis menonaktifkannya (`is_active=false`) di sisi database.
  App cukup terus mendaftarkan ulang token setiap `onTokenRefresh` seperti biasa.
- **Channel/topik FCM custom** — backend selalu kirim per-token (multicast by device
  token), tidak memakai topic subscription. Tidak perlu subscribe topic apa pun.

---

## 7. Referensi Silang

- Kontrak endpoint lengkap (request/response/error): `docs/api_contract.md` — cari
  `POST /api/v1/patients/device-tokens` dan `DELETE /api/v1/patients/device-tokens`.
- Skema tabel `device_push_tokens`: `docs/erd.md` §"Aksi & Komunikasi".
- Auth JWT pasien (header, TTL, refresh): `docs/redis.md` §2, §6.
