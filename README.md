# GitOps

Kumpulan stack `docker-compose.yml` untuk berbagai aplikasi.

Repositori ini adalah *Single Source of Truth* (SSOT) berbasis *Infrastructure as Code* (IaC) untuk otomasi *deployment* layanan VPS dan Cloud. Semua layanan di-deploy menggunakan Docker Compose dengan arsitektur modular, diproksikan secara terpusat menggunakan **Traefik**, dan dirancang untuk skalabilitas bisnis *hosting*.

Repositori ini berfokus pada layanan **hosting email**.

---

## Daftar Layanan

- [applications](https://github.com/kkynet/GitOps/tree/main/applications)
  - [glpi](https://github.com/kkynet/GitOps/tree/main/applications/glpi)
  - [nextcloud](https://github.com/kkynet/GitOps/tree/main/applications/nextcloud)
  - [transmission](https://github.com/kkynet/GitOps/tree/main/applications/transmission)
  - [vikunja](https://github.com/kkynet/GitOps/tree/main/applications/vikunja)
- [crowdsec](https://github.com/kkynet/GitOps/tree/main/crowdsec)
- [discourse](https://github.com/kkynet/GitOps/tree/main/discourse)
- [fossbilling](https://github.com/kkynet/GitOps/tree/main/fossbilling)
- [grafana](https://github.com/kkynet/GitOps/tree/main/grafana)
- [mailserver](https://github.com/kkynet/GitOps/tree/main/mailserver)
  - [dovecot](https://github.com/kkynet/GitOps/tree/main/mailserver/dovecot)
  - [mailman3](https://github.com/kkynet/GitOps/tree/main/mailserver/mailman3)
  - [postfix](https://github.com/kkynet/GitOps/tree/main/mailserver/postfix)
  - [redis](https://github.com/kkynet/GitOps/tree/main/mailserver/redis)
  - [roundcube](https://github.com/kkynet/GitOps/tree/main/mailserver/roundcube)
  - [rspamd](https://github.com/kkynet/GitOps/tree/main/mailserver/rspamd)
  - [unbound](https://github.com/kkynet/GitOps/tree/main/mailserver/unbound)
- [mariadb-galera](https://github.com/kkynet/GitOps/tree/main/mariadb-galera)
- [monitoring](https://github.com/kkynet/GitOps/tree/main/monitoring)
  - [prometheus](https://github.com/kkynet/GitOps/tree/main/monitoring/prometheus)
  - [smokeping](https://github.com/kkynet/GitOps/tree/main/monitoring/smokeping)
  - [zabbix](https://github.com/kkynet/GitOps/tree/main/monitoring/zabbix)
- [networking](https://github.com/kkynet/GitOps/tree/main/networking)
  - [rpz-kominfo-ubuntu](https://github.com/kkynet/GitOps/tree/main/networking/rpz-kominfo-ubuntu)
  - [unifi](https://github.com/kkynet/GitOps/tree/main/networking/unifi)
  - [wireguard](https://github.com/kkynet/GitOps/tree/main/networking/wireguard)
- [powerdns](https://github.com/kkynet/GitOps/tree/main/powerdns)
- [pterodactyl](https://github.com/kkynet/GitOps/tree/main/pterodactyl)
- [pterodactyl-wings](https://github.com/kkynet/GitOps/tree/main/pterodactyl-wings)
- [traefik](https://github.com/kkynet/GitOps/tree/main/traefik)


---

## Step-by-Step

Sebelum masuk ke langkah pertama, pastikan network sudah terbuat, atau gunakan alokasi IP otomatis dari Docker network. Repository ini menggunakan IP statik.

Network yang digunakan di repository ini adalah seperti di bawah. Sesuaikan dengan kebutuhan, jika berbeda bisa diubah.

### Daftar Network

```bash
docker network ls
```

```text
NETWORK ID     NAME          DRIVER    SCOPE
810cf5c26386   internal.60   ipvlan    local
c7e70418c78b   nat           bridge    local
```

### Detail Network `nat`

```bash
docker network inspect nat
```

```json
[
    {
        "Name": "nat",
        ...
        "Driver": "bridge",
        ...
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "10.0.5.0/24",
                    "Gateway": "10.0.5.1"
                }
            ]
        },
        "Internal": false,
        ...
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        ...
    }
]
```

### Detail Network `internal.60`

```bash
docker network inspect internal.60
```

```json
[
    {
        "Name": "internal.60",
        ...
        "Driver": "ipvlan",
        ...
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "10.0.2.0/24",
                    "Gateway": "10.0.2.1"
                }
            ]
        },
        "Internal": true,
        ...
        "ConfigOnly": false
        ...
    }
]
```

---

## 1. DNS (Powerdns)

Pertama yang di-setup adalah DNS. Direkomendasikan menggunakan **PowerDNS** karena sudah mendukung backend database SQL.

**[powerdns/](https://github.com/kkynet/GitOps/tree/main/powerdns)**

---

## 2. Reverse Proxy & SSL (Traefik)

Setelah DNS selesai, langkah berikutnya adalah **Traefik**. Traefik berfungsi sebagai reverse proxy terpusat dan men-generate SSL menggunakan **DNS Challenge** (Let's Encrypt).

Sertifikat dari `acme.json` dikonversi otomatis menjadi `.crt` dan `.key` oleh container `traefik-certs-dumper`, sehingga bisa dipakai oleh service seperti mailserver.

- **Provider:** `rfc2136`, karena DNS Authoritative di-setup sendiri (bukan Cloudflare)
- **Output sertifikat:** `.crt` dan `.key` untuk service non-Traefik
- **Tips:** gunakan server **staging** Let's Encrypt dulu untuk menghindari rate limit

**[traefik/](https://github.com/kkynet/GitOps/tree/main/traefik)**

---