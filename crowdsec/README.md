# CROWDSEC

**Intrusion Prevention System (IPS) menggunakan CrowdSec.**

CrowdSec adalah security engine open-source yang menganalisis log dari berbagai service (SSH, Postfix, Dovecot, Traefik, dsb) secara real-time untuk mendeteksi pola serangan (brute force, scanning, abuse, dll), lalu membuat keputusan ban berdasarkan skenario yang terdeteksi. Keputusan ban ini kemudian ditegakkan oleh **bouncer** — di sini menggunakan firewall bouncer yang berjalan di host untuk memblokir IP jahat langsung di level firewall (iptables/nftables). CrowdSec juga memiliki community threat intelligence (CrowdSec Console), sehingga IP yang terdeteksi menyerang bisa dibagikan dan diperkaya oleh data dari komunitas pengguna CrowdSec lainnya.

---

## Daftar Isi

- [Struktur File](#struktur-file)
- [Step-by-step](#step-by-step)
  - [1. Environment](#1-environment)
  - [2. Volumes](#2-volumes)
  - [3. Ports](#3-ports)
  - [4. Menjalankan Container](#4-menjalankan-container)
  - [5. Setup Firewall Bouncer di Host](#5-setup-firewall-bouncer-di-host)
  - [6. Integrasi CrowdSec ke Dashboard Web](#6-integrasi-crowdsec-ke-dashboard-web)

---

## Struktur File

```text
root@host:/crowdsec# tree -a
.
├── .env
└── docker-compose.yml
```

---

## Step-by-step

### 1. Environment

| Variable | Contoh | Keterangan |
|---|---|---|
| `COLLECTIONS` | `crowdsecurity/linux crowdsecurity/postfix crowdsecurity/dovecot` | Daftar *collection* yang otomatis di-install saat container start. Collection adalah paket berisi parser + skenario deteksi untuk jenis log/aplikasi tertentu — `crowdsecurity/linux` untuk log auth umum Linux (misal SSH brute force), `crowdsecurity/postfix` untuk pola serangan di log Postfix, dan `crowdsecurity/dovecot` untuk pola serangan di log Dovecot (misal brute force IMAP/POP3) |
| `TZ` | `Asia/Makassar` | Timezone container |
| `GID` | `1000` | Group ID di dalam container, disamakan dengan GID group `docker` di host agar container bisa mengakses `/var/run/docker.sock` tanpa masalah permission |

### 2. Volumes

| Volume | Keterangan |
|---|---|
| `/var/run/docker.sock:ro` | Di-mount read-only agar CrowdSec bisa membaca Docker API dan menggunakan *docker acquisition* — menarik log langsung dari container lain yang sedang berjalan (misal Traefik, Postfix) tanpa perlu bind-mount file log satu per satu |
| `/var/lib/crowdsec/data` | Database lokal CrowdSec (SQLite) — menyimpan alert, decision/ban yang aktif, dan kredensial machine/API |
| `/etc/crowdsec` | Direktori konfigurasi — collection, parser, skenario, profile, acquisition (`acquis.yaml`), dan `config.yaml` |

> Detail volume berdasarkan dokumentasi resmi: [crowdsecurity/crowdsec#volumes-1](https://hub.docker.com/r/crowdsecurity/crowdsec#volumes-1)

### 3. Ports

| Port | Keterangan |
|---|---|
| `8080` | Local API (LAPI) — endpoint utama yang dipakai bouncer dan `cscli` untuk berkomunikasi dengan CrowdSec engine |
| `6060` | Metrics endpoint (Prometheus) |

> **Catatan:** Jika salah satu port di atas diubah (misal menjadi `8084`), kemungkinan besar itu adalah port `8080` (LAPI), karena port ini paling umum bentrok dengan service lain. Cek kembali mapping port di `docker-compose.yml` untuk memastikan.

### 4. Menjalankan Container

```bash
docker compose up -d
```

### 5. Setup Firewall Bouncer di Host

Bouncer di sini dipasang langsung di host (bukan di dalam container) agar bisa langsung memblokir IP di level firewall host.

```bash
apt update
apt install crowdsec-firewall-bouncer
```

> **Catatan:** Pastikan repository APT resmi CrowdSec sudah ditambahkan terlebih dahulu sebelum `apt install` bisa menemukan paket ini. Perhatikan juga nama paket — tergantung firewall backend yang dipakai di host (`iptables` atau `nftables`), nama paketnya bisa jadi `crowdsec-firewall-bouncer-iptables` atau `crowdsec-firewall-bouncer-nftables`, bukan nama generik. Sesuaikan dengan yang benar-benar tersedia di repository kamu.

File `crowdsec-firewall-bouncer.yaml` sudah dilampirkan untuk referensi, dan bisa disimpan di:

```text
/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

Setelah itu, restart service `crowdsec-firewall-bouncer`:

```bash
systemctl restart crowdsec-firewall-bouncer.service
```

Berikut output yang diharapkan setelah restart:

```text
root@host:~# systemctl status crowdsec-firewall-bouncer.service
● crowdsec-firewall-bouncer.service - The firewall bouncer for CrowdSec
     Loaded: loaded (/etc/systemd/system/crowdsec-firewall-bouncer.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-10-26 11:14:40 WITA; 4 days ago
    Process: 9761 ExecStartPre=/usr/bin/crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml -t (code=exited, status=0/SUCCESS)
    Process: 10310 ExecStartPost=/bin/sleep 0.1 (code=exited, status=0/SUCCESS)
   Main PID: 10021 (crowdsec-firewa)
      Tasks: 11 (limit: 16725)
     Memory: 32.2M
        CPU: 1min 7.617s
     CGroup: /system.slice/crowdsec-firewall-bouncer.service
             └─10021 /usr/bin/crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml

Oct 26 11:14:34 docker4 systemd[1]: Starting crowdsec-firewall-bouncer.service - The firewall bouncer for CrowdSec...
Oct 26 11:14:40 docker4 systemd[1]: Started crowdsec-firewall-bouncer.service - The firewall bouncer for CrowdSec.
```

### 6. Integrasi CrowdSec ke Dashboard Web

Daftar akun di [app.crowdsec.net](https://app.crowdsec.net).

Di dashboard tersebut, klik **Add Instance** — akan diberikan sebuah kode unik (*Enrollment Key*).

Jalankan perintah ini di dalam container CrowdSec:

```bash
docker exec crowdsec cscli console enroll <kode_enroll>
```

Setelah itu, restart container CrowdSec agar enrollment diterapkan:

```bash
docker compose up -d --force-recreate
```
