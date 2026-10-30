# MAILSERVER/RSPAMD

**Spam Filter menggunakan Rspamd.**

Rspamd adalah mail filtering system yang menganalisis setiap pesan masuk (via integrasi dengan Postfix) untuk mendeteksi spam, menggunakan kombinasi rule-based scoring, Bayes classifier, DNSBL/RBL lookup, SPF/DKIM/DMARC check, dan lainnya.

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Dependensi](#1-dependensi)
  - [2. Build Image](#2-build-image)
  - [3. Environment](#3-environment)
  - [4. Volumes](#4-volumes)
  - [5. Ports](#5-ports)
  - [6. Labels](#6-labels)
  - [7. Menjalankan Container](#7-menjalankan-container)

---

## Struktur File

```text
root@docker4:/mailserver/rspamd# tree -a
.
├── .dockerignore
└── docker-compose.yml
```

---

## Step-by-step

### 1. Dependensi

Sebelum setup Rspamd, service ini bergantung pada [unbound/](https://github.com/kkynet/GitOps/tree/main/mailserver/unbound) dan [redis/](https://github.com/kkynet/GitOps/tree/main/mailserver/redis), karena unbound digunakan untuk resolve ke root hint agar menghindari rate limit, dan redis untuk cache data rspamd


### 2. Build Image

Tidak diperlukan build image untuk service ini.

### 3. Environment

Tidak diperlukan environment untuk service ini.

### 4. Volumes

| Volume | Keterangan |
|---|---|
| `/etc/rspamd/local.d` | Local configuration |
| `/var/lib/rspamd` | Learned data: Bayes (sqlite mode), fuzzy db, caches |
| `/var/log/rspamd` | Log |

> Detail volume berdasarkan dokumentasi resmi: [rspamd/rspamd-docker#persistent-data--volumes](https://github.com/rspamd/rspamd-docker#persistent-data--volumes)

### 5. Ports

| Port | Keterangan |
|---|---|
| `11332` | MTA integration |
| `11334` | Web UI |

> Detail port berdasarkan dokumentasi resmi: [rspamd/rspamd-docker#ports](https://github.com/rspamd/rspamd-docker#ports)

### 6. Labels

Label menyesuaikan saja. Di sini dibuat dengan path prefix `domain.com/rspamd`, bisa disesuaikan jika ingin menggunakan subdomain.

### 7. Menjalankan Container

```bash
docker compose up -d
```
