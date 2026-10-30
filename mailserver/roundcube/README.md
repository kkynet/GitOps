# MAILSERVER/ROUNDCUBE

**Roundcube untuk webmail client.**

Roundcube adalah webmail client berbasis browser, memungkinkan user mengakses email (via IMAP ke Dovecot dan SMTP ke Postfix) tanpa perlu mail client desktop. Stack ini terdiri dari 2 service: **mailserver-roundcube** (aplikasi webmail) dan **mailserver-roundcube-db** (database MariaDB Galera untuk menyimpan preferensi user, address book, dsb).

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Environment](#1-environment)
    - [mailserver-roundcube-db (.env)](#mailserver-roundcube-db-env)
    - [mailserver-roundcube (.env-roundcube)](#mailserver-roundcube-env-roundcube)
  - [2. Volumes](#2-volumes)
  - [3. Ports](#3-ports)
  - [4. Labels](#4-labels)
  - [5. Menjalankan Container](#5-menjalankan-container)

---

## Struktur File

```text
root@host:/mailserver/roundcube# tree -a
.
├── .dockerignore
├── .env
├── .env-roundcube
├── docker-compose.yml
├── mariadb-root
└── roundcube_db_user
```

---

## Step-by-step

### 1. Environment

#### mailserver-roundcube-db (.env)

| Variable | Contoh | Keterangan |
|---|---|---|
| `MARIADB_ROOT_PASSWORD_FILE` | `/run/secrets/mariadb-root` | Path ke file berisi root password (Docker secret), bukan password langsung |
| `MARIADB_DATABASE` | `roundcubemail` | Nama db untuk Roundcube, bisa bebas tetapi menyesuaikan dengan `ROUNDCUBEMAIL_DB_NAME` di `.env-roundcube` |
| `MARIADB_GALERA_CLUSTER_ADDRESS` | `gcomm://` | Alamat cluster Galera. Kosong = node ini bootstrap cluster baru; untuk join ke cluster yang sudah ada, diisi daftar node lain |
| `MARIADB_GALERA_MARIABACKUP_PASSWORD_FILE` | `/run/secrets/mariadb-root` | Path ke file password untuk user `mariabackup`, dipakai Galera saat proses State Snapshot Transfer (SST) antar node cluster |

#### mailserver-roundcube (.env-roundcube)

Environment yang dibutuhkan hanya ini saja, juga menyesuaikan. Environment official lengkap: [roundcube/roundcubemail-docker#configuration--environment-variables](https://github.com/roundcube/roundcubemail-docker#configurationenvironment-variables)

| Variable | Contoh | Keterangan |
|---|---|---|
| `ROUNDCUBEMAIL_DB_TYPE` | `mysql` | Jenis database yang digunakan Roundcube |
| `ROUNDCUBEMAIL_DB_HOST` | `mailserver-roundcube-db` | Host/service name database |
| `ROUNDCUBEMAIL_DB_PORT` | `3306` | Port database |
| `ROUNDCUBEMAIL_DB_NAME` | `roundcubemail` | Nama database, harus sama dengan `MARIADB_DATABASE` di `.env` |
| `ROUNDCUBEMAIL_DEFAULT_HOST` | `tls://imap-0.domain.com` | Host IMAP default yang dipakai Roundcube untuk login — prefix `tls://` berarti koneksi IMAP via STARTTLS |
| `ROUNDCUBEMAIL_DEFAULT_PORT` | `143` | Port IMAP yang dituju (port standar sebelum upgrade ke TLS via STARTTLS) |
| `ROUNDCUBEMAIL_SMTP_SERVER` | `tls://smtp-0.domain.com` | Host SMTP yang dipakai Roundcube untuk mengirim email — prefix `tls://` berarti koneksi SMTP via STARTTLS |
| `ROUNDCUBEMAIL_SMTP_PORT` | `587` | Port SMTP submission yang dituju |

### 2. Volumes

#### mailserver-roundcube-db

| Volume | Keterangan |
|---|---|
| `/bitnami/mariadb` | Data database (data directory MariaDB) |
| `/opt/bitnami` | Data konfigurasi Bitnami |

> Detail volume berdasarkan dokumentasi resmi Bitnami: [Persisting your database](https://github.com/bitnami/containers/tree/main/bitnami/mariadb-galera#persisting-your-database)

#### mailserver-roundcube

| Volume | Keterangan |
|---|---|
| `/var/www/html` | Roundcube installation root directory |
| `/var/roundcube/config` | Konfigurasi Roundcube |
| `/tmp/roundcube-temp` | Temp folder untuk attachment dan thumbnail image |

### 3. Ports

#### mailserver-roundcube

| Port | Keterangan |
|---|---|
| `80` | Port HTTP aplikasi web Roundcube, diakses lewat reverse proxy (Traefik) di depannya |

### 4. Labels

Label menyesuaikan saja. Di sini dibuat dengan subdomain `webmail.domain.com`.

### 5. Menjalankan Container

```bash
docker compose up -d
```
