# TRAEFIK

Setelah setting DNS, langkah selanjutnya adalah **Traefik**. Traefik digunakan untuk generate SSL menggunakan **DNS Challenge**.

Di sini menggunakan container `treafik-certs-dumper`. Ketika `acme.json` sudah ter-generate dari DNS Challenge, file tersebut akan dikonversi menjadi `.crt` dan `.key` untuk kebutuhan service mailserver dan lainnya. File `acme.json` hanya digunakan oleh Traefik beserta web-web lainnya.

```text
root@host:/letsencrypt/certs# tree
.
├── certs
│   └── domain.com.crt
└── private
    ├── letsencrypt.key
    └── domain.com.key
```

---

## Daftar Isi

- [Provider](#provider)
- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Generate tsig-key rfc2136](#1-generate-tsig-key-rfc2136)
  - [2. Generate htpasswd](#2-generate-htpasswd)
  - [3. Menjalankan Container](#3-menjalankan-container)
  - [Konfigurasi Let's Encrypt](#konfigurasi-lets-encrypt)

---

## Provider

Repository ini menggunakan provider **rfc2136** karena DNS Authoritative di-setup sendiri, bukan melalui Cloudflare atau provider lain.

---

## Struktur File

```text
root@docker4:/home/administrator/docker/tamvan/docker-compose/traefik# tree -a
.
├── .dockerignore
├── .env
├── README.md
├── docker-compose.yml
└── rfc2136_tsig_secret.txt
```

> **Catatan:** Jangan lupa mengubah isi `docker-compose.yml` dengan menghapus `-sample` pada nama file agar sesuai dengan struktur file di atas.

---

## Step-by-step

### 1. Generate tsig-key rfc2136

Karena menggunakan rfc2136, wajib generate TSIG key terlebih dahulu jika belum ada.

```bash
pdnsutil generate-tsig-key keyname hmac-sha512
```

Output yang diharapkan:

```text
Create new TSIG key keyname hmac-sha512 W/Thm...iMA/tphc...9BA==
```

Setelah itu, masukkan key ke `rfc2136_tsig_secret.txt`:

```text
W/Thm...iMA/tphc...9BA==
```

Pastikan juga di `.env-powerdns-auth` untuk service **powerdns/** sudah diisi:

```env
PDNS_dnsupdate=yes
```

### 2. Generate htpasswd

`htpasswd` diperlukan untuk dashboard Traefik. Bisa di-generate langsung di host, asal sudah terpasang `apache2-utils` atau `httpd-tools`.

```bash
echo $(htpasswd -n -B admin yourpassword)
```

Output yang diharapkan:

```text
admin:$$2y$$...
```

Setelah itu, masukkan hasilnya ke `.env` pada parameter `TRAEFIK_DASHBOARD_CREDENTIALS`.

### 3. Menjalankan Container

Setelah konfigurasi selesai, jalankan container:

```bash
docker-compose up -d
```

---

## Konfigurasi Let's Encrypt

File `traefik-sample.yaml` sudah disediakan sebagai referensi konfigurasi.

> **Tips:** Agar tidak terkena *rate limiting* dari server Let's Encrypt, gunakan server **staging** terlebih dahulu. Setelah `acme.json` berhasil ter-generate, ganti ke server **production**.
>
> Indikator keberhasilan: jika gagal, `acme.json` akan kosong. Jika berhasil, `acme.json` akan berisi data.

**Staging:**

```yaml
...
caServer: https://acme-staging-v02.api.letsencrypt.org/directory # staging
...
```

**Production:**

```yaml
...
caServer: https://acme-v02.api.letsencrypt.org/directory # prod (default)
...
```

---

Setelah semua container **healthy**, lanjutkan ke langkah berikutnya: **[mailserver/*](https://github.com/kkynet/GitOps/tree/main/mailserver)**.
