# MAILSERVER/MAILMAN3

**Mailing List Manager menggunakan Mailman3.**

Stack ini terdiri dari 4 service yang saling terhubung:

- **mailserver-mailman-core** - engine utama Mailman3, menangani logika mailing list (subscribe, moderasi, delivery) dan menerima pesan dari Postfix via LMTP
- **mailserver-mailman-web**  web UI berbasis Django (Postorius untuk admin list, HyperKitty untuk arsip/archiver)
- **mailserver-mailman-db** - database MariaDB Galera sebagai backend data Mailman
- **mailserver-mailman-nginx** - reverse proxy untuk serve static content dari mailman-web

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Environment](#1-environment)
    - [mailserver-mailman-db (.env)](#mailserver-mailman-db-env)
    - [mailserver-mailman-core (.env-mailman-core)](#mailserver-mailman-core-env-mailman-core)
    - [mailserver-mailman-web (.env-mailman-web)](#mailserver-mailman-web-env-mailman-web)
  - [2. Volumes](#2-volumes)
  - [3. Ports](#3-ports)
  - [4. Menjalankan Container](#4-menjalankan-container)

---

## Struktur File

```text
root@host:/mailserver/mailman3# tree -a
.
├── .dockerignore
├── .env
├── .env-mailman-core
├── .env-mailman-web
├── docker-compose.yml
├── mailman-pass
├── mailman-user
└── mariadb-root
```

---

## Step-by-step

### 1. Environment

#### mailserver-mailman-db (.env)

| Variable | Contoh | Keterangan |
|---|---|---|
| `MARIADB_ROOT_PASSWORD_FILE` | `/run/secrets/mariadb-root` | Path ke file berisi root password (Docker secret), bukan password langsung |
| `MARIADB_USER_FILE` | `/run/secrets/mailman-user` | Path ke file berisi user untuk db |
| `MARIADB_PASSWORD_FILE` | `/run/secrets/mailman-pass` | Path ke file berisi password untuk db |
| `MARIADB_DATABASE` | `mailman` | Nama db untuk mailman, bisa bebas tetapi menyesuaikan |
| `MARIADB_CHARACTER_SET` | `utf8mb4` | Character set yang mendukung Unicode penuh (termasuk emoji) |
| `MARIADB_COLLATE` | `utf8mb4_unicode_ci` | Aturan sorting/pembanding string untuk charset di atas — `ci` berarti *case-insensitive* |
| `MARIADB_GALERA_CLUSTER_ADDRESS` | `gcomm://` | Alamat cluster Galera. Kosong = node ini bootstrap cluster baru; untuk join ke cluster yang sudah ada, diisi daftar node lain |
| `MARIADB_GALERA_MARIABACKUP_PASSWORD_FILE` | `/run/secrets/mariadb-root` | Path ke file password untuk user `mariabackup`, dipakai Galera saat proses State Snapshot Transfer (SST) antar node cluster |

#### mailserver-mailman-core (.env-mailman-core)

Environment yang dibutuhkan hanya ini saja, menyesuaikan saja. Environment official lengkap: [maxking/docker-mailman#mailman-core](https://github.com/maxking/docker-mailman#mailman-core-1)

| Variable | Contoh | Keterangan |
|---|---|---|
| `DATABASE_TYPE` | `mysql` | Jenis database yang digunakan Mailman Core |
| `DATABASE_URL` | `mysql+pymysql://mailman:mailmanpass@mailserver-mailman-db/mailman?charset=utf8mb4&use_unicode=1` | Connection string lengkap ke database (driver, user, password, host, nama db, charset) |
| `HYPERKITTY_API_KEY` | `hyperkittysecretapi` | Shared secret antara Core dan HyperKitty (archiver di mailman-web), harus sama persis dengan nilai di mailman-web |
| `HYPERKITTY_URL` | `https://lists.domain.com/hyperkitty` | Endpoint HyperKitty yang dituju Core untuk mem-forward pesan list ke archiver |
| `MTA` | `postfix` | MTA yang diintegrasikan dengan Core, dipakai untuk generate konfigurasi transport map Postfix |
| `SMTP_HOST` | `smtp-0.domain.com` | Host SMTP yang dipakai Core untuk mengirim email keluar (notifikasi, broadcast list, dll) |
| `SMTP_PORT` | `587` | Port SMTP submission yang dituju |
| `SMTP_HOST_USER` | `mailman@domain.com` | Username SMTP AUTH untuk Core mengirim email |
| `SMTP_HOST_PASSWORD` | `mailmanrootpass` | Password SMTP AUTH untuk user di atas |
| `SMTP_SECURE_MODE` | `starttls` | Mode enkripsi koneksi SMTP yang dipakai Core |
| `MM_HOSTNAME` | `mailserver-mailman-core` | Hostname internal Core, dipakai komponen lain (web/REST) untuk mengenali instance ini |
| `MAILMAN_REST_USER` | `restadmin` | Username REST API internal Core |
| `MAILMAN_REST_PASSWORD` | `restadmin` | Password REST API internal Core, dipakai mailman-web (Postorius) untuk mengontrol Core (create list, dsb) |

#### mailserver-mailman-web (.env-mailman-web)

Environment yang dibutuhkan hanya ini saja, juga menyesuaikan. Environment official lengkap: [maxking/docker-mailman#mailman-web](https://github.com/maxking/docker-mailman#mailman-web-1)

| Variable | Contoh | Keterangan |
|---|---|---|
| `SMTP_HOST` | `smtp-0.domain.com` | Host SMTP yang dipakai Web (Django) untuk kirim notifikasi (reset password, dsb), bisa beda akun dari Core |
| `SMTP_PORT` | `587` | Port SMTP submission |
| `SMTP_HOST_USER` | `mailer@domain.com` | Username SMTP AUTH untuk Web |
| `SMTP_HOST_PASSWORD` | `mailerrootpass` | Password SMTP AUTH untuk user di atas |
| `SMTP_USE_TLS` | `True` | Mengaktifkan TLS saat Web connect ke SMTP host |
| `SERVE_FROM_DOMAIN` | `lists.domain.com` | Domain utama yang dilayani Postorius/HyperKitty |
| `HYPERKITTY_API_KEY` | `hyperkittysecretapi` | Harus sama dengan nilai di mailman-core, agar Core & Web/HyperKitty bisa saling autentikasi |
| `MAILMAN_ADMIN_USER` | `administrator` | Username admin default untuk login ke Postorius |
| `MAILMAN_ADMIN_EMAIL` | `mailman@domain.com` | Email akun admin di atas |
| `SECRET_KEY` | `secretapi` | Django secret key, dipakai untuk signing session/cookie, wajib unik & dirahasiakan |
| `DATABASE_TYPE` | `mysql` | Jenis database yang digunakan Web |
| `DATABASE_URL` | `mysql://mailman:mailmanpass@mailserver-mailman-db/mailman?charset=utf8mb4` | Connection string database untuk Django ORM |
| `MAILMAN_REST_URL` | `http://mailserver-mailman-core:8001` | Endpoint REST API Mailman Core yang dipanggil Web |
| `MAILMAN_REST_USER` | `restadmin` | Username REST API (harus sama dengan di Core) |
| `MAILMAN_REST_PASSWORD` | `restadmin` | Password REST API (harus sama dengan di Core) |
| `MAILMAN_HOSTNAME` | `lists.domain.com` | Hostname default yang dipakai untuk referensi list |
| `POSTORIUS_TEMPLATE_BASE_URL` | `https://lists.domain.com` | Base URL yang dipakai di template email Postorius (misal link konfirmasi subscribe) |
| `DYLD_LIBRARY_PATH` | `/usr/local/mysql/lib/` | Path library client MySQL. Variabel ini sebenarnya khusus macOS (dynamic loader path) — kemungkinan sisa dari base image dan tidak berpengaruh di Linux container, perlu dicek apakah benar-benar dipakai |
| `DJANGO_ALLOWED_HOSTS` | `lists.domain.com` | Daftar host yang diizinkan Django menerima request, untuk mencegah Host header injection |

> **Catatan:** Container `mailserver-mailman-nginx` wajib dipakai karena untuk keperluan static konten `mailserver-mailman-web`.

### 2. Volumes

#### mailserver-mailman-db

| Volume | Keterangan |
|---|---|
| `/bitnami/mariadb` | Data database (data directory MariaDB) |
| `/opt/bitnami` | Data konfigurasi Bitnami |

> Detail volume berdasarkan dokumentasi resmi Bitnami: [Persisting your database](https://github.com/bitnami/containers/tree/main/bitnami/mariadb-galera#persisting-your-database)

#### mailserver-mailman-core

| Volume | Keterangan |
|---|---|
| `/opt/mailman/` | Data runtime Mailman Core, konfigurasi yang di-generate otomatis, queue pesan (incoming/outgoing), data list, lock file, dsb. Wajib persistent agar data list tidak hilang saat container restart |

#### mailserver-mailman-web

| Volume | Keterangan |
|---|---|
| `/opt/` | Data runtime Mailman Web (Postorius + HyperKitty), termasuk static file hasil `collectstatic`, media upload (misal avatar/header list), dan file konfigurasi Django lain yang di-generate otomatis saat container start |

#### mailserver-mailman-nginx

| Volume | Keterangan |
|---|---|
| `/opt/mailman/web` | Di-share (read-only) dari volume `/opt/` milik container mailman-web, supaya Nginx bisa langsung serve static file (CSS, JS, gambar) tanpa melalui Django — mengurangi beban aplikasi dan mempercepat loading halaman |
| `/etc/nginx/conf.d/default.conf` | File konfigurasi vhost Nginx untuk reverse-proxy ke mailman-web dan serve static dari volume di atas |

### 3. Ports

#### mailserver-mailman-core

| Port | Keterangan |
|---|---|
| `8001` | REST API Mailman Core, dipanggil mailman-web (Postorius) untuk operasi administratif (create list, dsb) |
| `8024` | LMTP Mailman Core, menerima pesan masuk dari MTA (Postfix) untuk diproses sebagai mailing list |

#### mailserver-mailman-web

| Port | Keterangan |
|---|---|
| `127.0.0.7:8082:8080` | Port aplikasi web (Django/Gunicorn) di bind hanya ke `127.0.0.7:8082` di host, tidak diekspos langsung ke publik, diakses lewat reverse proxy (Nginx/Traefik) di depannya |

#### mailserver-mailman-nginx

Menggunakan port `80`, atau langsung diakses via Traefik dengan menambahkan label (tanpa expose port langsung ke host).

### 4. Menjalankan Container

```bash
docker compose up -d
```
