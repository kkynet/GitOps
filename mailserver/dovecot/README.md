# MAILSERVER/DOVECOT

**MDA menggunakan Dovecot.**

Dovecot berfungsi sebagai *Mail Delivery Agent* (MDA) sekaligus server IMAP/POP3 yang digunakan mail client untuk mengakses mailbox. Selain menerima pesan dari Postfix via LMTP untuk *final delivery* ke mailbox user, Dovecot juga berperan sebagai penyedia SASL authentication untuk SMTP AUTH, sehingga kedua service ini saling terintegrasi melalui socket yang di share.

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
root@host:/mailserver/dovecot# tree -a
.
├── .dockerignore
├── .env
├── Dockerfile
├── conf.d
│   ├── 10-auth.conf
│   └── auth-sql.conf.ext
├── docker-compose.yml
├── docker-entrypoint.sh
├── dovecot.conf
├── mysql
│   └── dovecot-mysql.conf
└── protocols.d
    ├── imapd.protocol
    ├── lmtpd.protocol
    ├── managesieved.protocol
    └── pop3d.protocol

4 directories, 17 files
```

---

## Step-by-step

### 1. Build Image

Buat image terlebih dahulu. Nama image menyesuaikan dengan yang ada di `docker-compose.yml`.

```bash
docker build . -t mailserver-dovecot:latest
```

### 2. Environment

Environment yang didukung sebagai berikut:

| Variable | Contoh |
|---|---|
| `MYSQL_HOST` | `mysql-host` |
| `MYSQL_PORT` | `3306` |
| `MYSQL_DATABASE` | `mx` |
| `MYSQL_USER` | `postfix` |
| `MYSQL_PASSWORD` | `postfixpass` |
| `VMAIL_UID` | `5000` |
| `VMAIL_GID` | `5000` |
| `POSTFIX_UID` | `100` |
| `POSTFIX_GID` | `101` |
| `TZ` | `Asia/Makassar` |

> `MYSQL_*` digunakan Dovecot untuk query data user/domain virtual mail dari database yang sama dengan Postfix. `VMAIL_UID`/`VMAIL_GID` adalah UID/GID pemilik mailbox di `/srv/vmail`, sedangkan `POSTFIX_UID`/`POSTFIX_GID` harus sama dengan UID/GID user Postfix di container `mailserver/postfix` agar kedua container bisa saling mengakses socket di `/var/spool/postfix/private` tanpa masalah permission.

### 3. Volumes

| Volume | Keterangan |
|---|---|
| `/var/spool/postfix/private` | Direktori socket internal, di share dengan container Postfix. Dovecot menyediakan socket di sini untuk dua keperluan: autentikasi SASL (agar Postfix bisa validasi SMTP AUTH user via Dovecot) dan socket LMTP (agar Postfix bisa mengirim pesan masuk ke Dovecot untuk final delivery ke mailbox) |
| `/srv/vmail` | Lokasi penyimpanan mailbox virtual (format Maildir) untuk seluruh domain dan user. Ini adalah data mail yang sesungguhnya, jadi wajib persistent dan di-backup |
| `/etc/dovecot/dovecot.conf` | Konfigurasi utama Dovecot |
| `/etc/dovecot/vendor.d` | Direktori berisi konfigurasi bawaan/default dari image Dovecot (vendor defaults), terpisah dari custom override di `conf.d/` agar tidak ikut tertimpa saat image di-update |
| `/etc/dovecot/ssl/cert.crt` | Sertifikat SSL untuk IMAPS/POP3S |
| `/etc/dovecot/ssl/cert.key` | Private key SSL untuk IMAPS/POP3S |

### 4. Ports

| Port | Keterangan |
|---|---|
| `143:143` | IMAP, akses mailbox tidak terenkripsi secara default, bisa upgrade ke TLS via STARTTLS |
| `993:993` | IMAPS, IMAP dengan implicit TLS (terenkripsi sejak awal koneksi) |
| `110:110` | POP3, akses mailbox tidak terenkripsi secara default, bisa upgrade ke TLS via STARTTLS |
| `995:995` | POP3S,  POP3 dengan implicit TLS |
| `24:24` | LMTP, port standar untuk menerima pesan dari Postfix (final delivery ke mailbox) |
| `4190:4190` | ManageSieve, untuk mengelola filter/sieve script mail secara remote (misal dari plugin filter di Roundcube) |

### 5. Menjalankan Container

```bash
docker compose up -d
```

### 6. Pembuatan Mail dan Mailbox baru

Pembuatan email membutuhkan password hash dengan prefix scheme (`{SHA512-CRYPT}$6$...`). Cara paling aman generate-nya langsung dari container Dovecot:

```bash
doveadm pw -s SHA512-CRYPT
```

Nanti diminta input password dua kali (konfirmasi). Output yang diharapkan seperti ini:

```text
{SHA512-CRYPT}$6$i/TPECfQ61...aPKG/
```

Copy hash tersebut dan input-kan di field `password` saat insert ke database `mx` (dijalankan dari container `mariadb-galera`)

### 7. Verifikasi dari Container Dovecot

Cek apakah Dovecot bisa resolve user-nya lewat `userdb`, dengan command:

```bash
doveadm user newuser@domain.com
```

Output yang diharapkan:

```text
root@dovecot:/# doveadm user info@domain.com
field   value
uid     5000
gid     5000
home    /var/vmail/domain.com/info/
mail    maildir:/var/vmail/domain.com/info/
quota_rule      *:storage=0M
quota_rule2     *:messages=0
```

Lalu test autentikasi lewat `passdb`:

```bash
doveadm auth test newuser@domain.com
```

Perintah ini akan menampilkan prompt password.

Jika **gagal**, akan muncul seperti ini:

```text
root@dovecot:/# doveadm auth test newuser@domain.com
Password:
passdb: newuser@domain.com auth failed
extra fields:
  user=newuser@domain.com
```

Jika **sukses**, akan muncul seperti ini:

```text
root@dovecot:/# doveadm auth test newuser@domain.com
Password:
passdb: newuser@domain.com auth succeeded
extra fields:
  user=newuser@domain.com
```
