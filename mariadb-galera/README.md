# MARIADB-GALERA (Node0-Global)

**Database yang dipakai MariaDB Galera.**

Container ini diperuntukkan untuk aplikasi yang membutuhkan database. Untuk case ini, `node0-mariadb` dipakai oleh **mailserver** sebagai query user, password, mailbox, alias, dsb.

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Image](#1-image)
  - [2. Environment](#2-environment)
  - [3. Volumes](#3-volumes)
  - [4. Menjalankan Container](#4-menjalankan-container)
- [Setup Struktur Database](#setup-struktur-database)
  - [1. Database (`mx`)](#1-database-mx)
  - [2. Table](#2-table)
    - [Deskripsi Tabel `mail_domain`](#deskripsi-tabel-mail_domain)
    - [Deskripsi Tabel `mail_user`](#deskripsi-tabel-mail_user)
- [Setup Domain dan Mailbox](#setup-domain-dan-mailbox)
  - [1. Domain](#1-domain)
  - [2. Mailbox](#2-mailbox)
  - [3. Verifikasi dari Container Dovecot](#3-verifikasi-dari-container-dovecot)

---

## Struktur File

```text
root@host:/mariadb-galera# tree -a
.
├── .dockerignore
├── .env
├── docker-compose.yml
└── mariadb-root
```

---

## Step-by-step

### 1. Image

Image yang digunakan yaitu MariaDB Galera milik Bitnami: `bitnamilegacy/mariadb-galera:12.0`. Alasan menggunakan Galera adalah untuk keperluan replikasi database ke node lain sebagai redundansi. Bisa disesuaikan jika ingin menggunakan MariaDB biasa (non-cluster).

```bash
docker pull bitnamilegacy/mariadb-galera:12.0
```

### 2. Environment

Environment yang dibutuhkan sebagai berikut:

| Variable | Contoh | Keterangan |
|---|---|---|
| `MARIADB_ROOT_PASSWORD_FILE` | `/run/secrets/mariadb-root` | Path ke file berisi root password (Docker secret), bukan password langsung |
| `MARIADB_GALERA_CLUSTER_ADDRESS` | `gcomm://` | Alamat cluster Galera menggunakan protokol `gcomm://`. Nilai kosong (`gcomm://` tanpa daftar host) berarti node ini melakukan **bootstrap** cluster baru (node pertama). Untuk node tambahan yang join ke cluster yang sudah ada, nilainya diisi daftar address node lain, contoh: `gcomm://node0,node1,node2` |
| `MARIADB_GALERA_MARIABACKUP_PASSWORD_FILE` | `/run/secrets/mariadb-root` | Path ke file password untuk user `mariabackup`, dipakai Galera saat proses State Snapshot Transfer (SST) antar node cluster |

> Environment detail lain yang didukung bisa dilihat di dokumentasi resmi Bitnami: [Customizable environment variables](https://github.com/bitnami/containers/tree/main/bitnami/mariadb-galera#customizable-environment-variables)

### 3. Volumes

| Volume | Keterangan |
|---|---|
| `/bitnami/mariadb` | Data database (data directory MariaDB) |
| `/opt/bitnami` | Data konfigurasi Bitnami |

> Detail volume berdasarkan dokumentasi resmi Bitnami: [Persisting your database](https://github.com/bitnami/containers/tree/main/bitnami/mariadb-galera#persisting-your-database)

### 4. Menjalankan Container

```bash
docker compose up -d
```

---

## Setup Struktur Database

Berikut struktur database yang digunakan. Ke depannya akan diotomasi untuk pembuatan struktur database.

### 1. Database (`mx`)

Nama database: `mx`

### 2. Table

| Tabel | Keterangan |
|---|---|
| `mail_domain` | List domain yang dilayani mail server |
| `mail_user` | Data user mailbox, email, password hash, path mailbox & quota |
| `mail_forwarding` | Alias/forwarding email, *WIP* |
| `mail_access` | Ke depannya dipergunakan untuk mail access, untuk saat ini masih opsional |

#### Deskripsi Tabel `mail_domain`

| Kolom | Keterangan |
|---|---|
| `id` | Primary key, auto increment |
| `domain` | Nama domain, contoh: `domain.com` |
| `active` | Status aktif domain (`y` / `n`) |

#### Deskripsi Tabel `mail_user`

| Kolom | Keterangan |
|---|---|
| `id` | Primary key, auto increment |
| `domain_id` | Foreign key ke `mail_domain.id` |
| `email` | Alamat email lengkap (`user@domain.com`), dipakai sebagai identifier utama saat login (parameter `%u` di query Dovecot) |
| `login` | Username login, pada data yang ada nilainya sama dengan `email` |
| `password` | Hash password dengan prefix scheme, contoh: `{SHA512-CRYPT}$6$...` |
| `name` | Nama lengkap / display name user |
| `maildir` | Path relatif mailbox dalam format Maildir, contoh: `domain.com/user1/` — digabung dengan `/var/vmail/` di `user_query` untuk membentuk home & mail path |
| `quota` | Quota storage dalam MB. `0` = unlimited |
| `active` | Status aktif user (`y` / `n`), hanya user dengan `active='y'` yang bisa login/menerima mail |

---

## Setup Domain dan Mailbox

### 1. Domain

Tambahkan domain terlebih dahulu ke database `mx`:

```sql
INSERT INTO mail_domain (domain, active) VALUES ('domain.com', 'y');
```

### 2. Mailbox

Pembuatan email membutuhkan password hash dengan prefix scheme (`{SHA512-CRYPT}$6$...`). Cara paling aman generate-nya langsung dari container Dovecot:

Contoh pembuatan ada disini [Pembuatan Mail dan Mailbox baru](https://github.com/kkynet/GitOps/tree/main/mailserver/dovecot#6-pembuatan-mail-dan-mailbox-baru)

Copy hash tersebut dan input-kan di field `password` saat insert ke database `mx` (dijalankan dari container `mariadb-galera`):

```sql
INSERT INTO mail_user (domain_id, email, login, password, name, maildir, quota, active)
VALUES (
    (SELECT id FROM mail_domain WHERE domain = 'domain.com'),
    'newuser@domain.com',
    'newuser@domain.com',
    '{SHA512-CRYPT}$6$<generate menggunakan doveadm pw -s SHA512-CRYPT>',
    'Nama User',
    'domain.com/newuser/',
    1000,
    'y'
);
```

Catatan field:

- `maildir`: `domain.com/newuser/` ini digabung dengan `/var/vmail/` di `user_query` Dovecot.
- `quota` dalam MB, `0` = unlimited.

### 3. Verikasi Mail dan Mailbox

Verifikasi mail dan mailbox di sini [Verifikasi dari Container Dovecot](https://github.com/kkynet/GitOps/tree/main/mailserver/dovecot#7-verifikasi-dari-container-dovecot)