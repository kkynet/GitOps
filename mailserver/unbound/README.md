# MAILSERVER/UNBOUND

**DNS Resolver menggunakan Unbound.**

Unbound digunakan untuk resolve ke root hint agar menghindari rate limit. Sebagai *recursive resolver* lokal, query DNS di-resolve langsung mulai dari root hint hingga ke authoritative server, bukan diteruskan ke resolver publik pihak ketiga — sehingga lookup lebih privat dan tidak terkena rate limit dari resolver eksternal. Service ini dipakai oleh [rspamd/](https://github.com/kkynet/GitOps/tree/main/mailserver/rspamd) untuk kebutuhan DNS lookup (DNSBL/RBL, SPF, validasi DKIM, dsb).

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Menjalankan Container](#1-menjalankan-container)

---

## Struktur File

```text
root@docker4:/mailserver/unbound# tree -a
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
