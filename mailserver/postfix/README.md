# MAILSERVER/POSTFIX

**MTA (SMTP) menggunakan Postfix.**

Postfix berfungsi sebagai *Mail Transfer Agent* (MTA) yang menangani pengiriman dan penerimaan email melalui protokol SMTP, baik untuk komunikasi antar mail server (relay/receiving dari internet) maupun untuk penerimaan pesan dari mail client (submission). Service ini menjadi pintu masuk/keluar utama untuk semua trafik email di stack mailserver.

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Build Image](#1-build-image)
  - [2. Environment](#2-environment)
  - [3. Volumes](#3-volumes)
  - [4. Ports](#4-ports)
  - [5. Menjalankan Container](#5-menjalankan-container)

---

## Struktur File

```text
root@host:/mailserver/postfix# tree -a
.
├── .dockerignore
├── .env
├── Dockerfile
├── docker-compose.yml
└── run.sh

1 directory, 8 files
```

---

## Step-by-step

### 1. Build Image

Buat image terlebih dahulu. Nama image menyesuaikan dengan yang ada di `docker-compose.yml`.

```bash
docker build . -t mailserver-postfix:latest
```

### 2. Environment

Environment yang didukung sebagai berikut:

| Variable | Contoh |
|---|---|
| `SMTP_SERVER` | `mx0.domain.com` |
| `SERVER_HOSTNAME` | `mx0.domain.com` |
| `TZ` | `Asia/Makassar` |

### 3. Volumes

| Volume | Keterangan |
|---|---|
| `/etc/postfix` | Konfigurasi dan data Postfix |
| `/etc/letsencrypt` | Sertifikat SSL |
| `/var/spool/postfix/private` | Direktori spool untuk Unix domain socket internal Postfix. Di sinilah socket yang digunakan Dovecot untuk SASL authentication (agar Postfix bisa autentikasi user SMTP AUTH via Dovecot) dan/atau socket LMTP untuk final delivery pesan ke Dovecot disimpan. Volume ini perlu di-share dengan container Dovecot agar integrasi keduanya berjalan |
| `/opt/mailman/` | Keperluan Mailman3 (opsional, tapi disarankan untuk mailing list) |

### 4. Ports

| Port | Keterangan |
|---|---|
| `25` | SMTP — port standar untuk komunikasi antar MTA (mail server ke mail server), digunakan untuk menerima/relay email dari server lain di internet. Umumnya tidak terenkripsi secara default, bisa upgrade ke TLS via STARTTLS |
| `465` | SMTPS — SMTP dengan implicit TLS/SSL (koneksi langsung terenkripsi sejak awal, tanpa STARTTLS). Umumnya digunakan oleh mail client untuk submission pesan secara aman |
| `587` | SMTP Submission, port untuk mail client (MUA) mengirim email melalui server ini. Biasanya mewajibkan autentikasi (SMTP AUTH) dan menggunakan STARTTLS untuk enkripsi |

### 5. Menjalankan Container

```bash
docker compose up -d
```
