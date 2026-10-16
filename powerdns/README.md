# POWERDNS dan POWERDNS ADMIN

Pertama yang di setup adalah DNS. Di rekomendasikan menggunakan **PowerDNS** karena sudah mendukung backend database SQL

---

## 1. Konfigurasi DNS Zone

Contoh zone file untuk domain `domain.com`. Ganti `192.168.1.x` dengan IP server Anda

```text
[root@ns /]# pdnsutil list-zone domain.com
```

```text
$ORIGIN .

; ===== A Record =====
domain.com              604800  IN  A      192.168.1.x   ; mandatory A record
ns1.domain.com          604800  IN  A      192.168.1.x   ; powerdns/ dns auth service
panel.domain.com        604800  IN  A      192.168.1.x   ; fossbilling/ service
traefik.domain.com      604800  IN  A      192.168.1.x   ; traefik/ service
webmail.domain.com      604800  IN  A      192.168.1.x   ; mailserver/roundcube service
mx0.domain.com          604800  IN  A      192.168.1.x   ; mailserver/dovecot & mailserver/dovecot service
lists.domain.com        604800  IN  A      192.168.1.x   ; mailserver/mailman3 service
dns-panel.domain.com     86400  IN  A      192.168.1.x   ; powerdnsadmin/ service

; ===== NS Record =====
domain.com              604800  IN  NS     ns1.domain.com.   ; mandatory NS record

; ===== CNAME (canonical or A record) =====
imap-0.domain.com       604800  IN  CNAME  mx0.domain.com.
pop3-0.domain.com       604800  IN  CNAME  mx0.domain.com.
smtp-0.domain.com       604800  IN  CNAME  mx0.domain.com.

; ===== MX Record =====
domain.com              604800  IN  MX     10 mx0.domain.com.   ; mandatory MX record

; ===== Email Security =====
mx0._domainkey.domain.com   604800  IN  TXT  "v=DKIM1; k=rsa; " "p=key"   ; mandatory record for email
domain.com                  604800  IN  SOA  ns1.domain.com root.ns1.domain.com 2026101412 604800 86400 2419200 604800
domain.com                  604800  IN  TXT  "v=spf1 mx:domain.com -all"   ; mandatory record for email
_dmarc.domain.com           604800  IN  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@domain.com; ruf=mailto:dmarc@domain.com; fo=1"   ; mandatory record for email (must set dkim and spf first)
```

---

## 2. Step-by-Step

### Clone Repository

```bash
git clone https://github.com/kkynet/GitOps
```

### Struktur File

Copy semua file `*-sample` dan ubah namanya sesuai struktur di bawah ini:

```text
root@host:/powerdns# tree
.
├── .dockerignore
├── .env
├── .env-powerdns-auth
├── .env-powerdnsadmin
├── .env-powerdnsadmin-mysql
├── db_uri                          # SQLALCHEMY_DATABASE_URI_FILE untuk .env-powerdnsadmin
├── docker-compose.yml
├── key_secret                      # SECRET_KEY_FILE untuk .env-powerdnsadmin
├── mariadb-root
├── mariadb-root-powerdnsadmin
├── powerdns-pass
├── powerdns-user
├── powerdnsadmin-pass
└── powerdnsadmin-user
```

> **Catatan:** Jangan lupa mengubah isi `docker-compose.yml` dengan menghapus `-sample` pada nama file agar sesuai dengan struktur file di atas

### Menjalankan Container

Setelah konfigurasi selesai, jalankan container:

```bash
docker-compose up -d
```

Setelah semua container **healthy**, lanjutkan ke langkah berikutnya: **[traefik/](https://github.com/kkynet/GitOps/tree/main/traefik)**.