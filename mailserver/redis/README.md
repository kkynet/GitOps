# MAILSERVER/REDIS

**In-memory data store menggunakan Redis.**

Redis dipakai untuk kebutuhan cache. Service ini dipakai oleh [rspamd/](https://github.com/kkynet/GitOps/tree/main/mailserver/rspamd) sebagai backend penyimpanan untuk data yang sering diakses dan berubah, seperti cache hasil scoring, statistik Bayes classifier, data greylisting, dan rate limiting.

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Menjalankan Container](#1-menjalankan-container)

---

## Struktur File

```text
root@host:/mailserver/redis# tree -a
.
├── .dockerignore
└── docker-compose.yml
```

---

## Step-by-step

### 1. Menjalankan Container

```bash
docker compose up -d
```
