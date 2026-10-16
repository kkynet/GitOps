# GitOps

Kumpulan stack `docker-compose.yml` untuk berbagai aplikasi.

Repositori ini adalah *Single Source of Truth* (SSOT) berbasis *Infrastructure as Code* (IaC) untuk otomasi *deployment* layanan VPS dan Cloud. Semua layanan di-deploy menggunakan Docker Compose dengan arsitektur modular, diproksikan secara terpusat menggunakan **Traefik**, dan dirancang untuk skalabilitas bisnis *hosting*.

Repositori ini berfokus pada layanan **hosting email**.

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

## 4. DNS & Networking

Pertama yang di-setup adalah DNS. Direkomendasikan menggunakan **PowerDNS** karena sudah mendukung backend database SQL.

👉 **[powerdns/](https://github.com/kkynet/GitOps/tree/main/powerdns)**


README.md WIP