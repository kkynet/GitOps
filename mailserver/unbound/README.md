# Unbound

Unbound digunakan untuk resolve ke root hint agar menghindari rate limit

## Struktur File

root@docker4:/mailserver/unbound# tree -a
.
├── .dockerignore
└── docker-compose.yml

### 1. Menjalankan Container

```bash
docker compose up -d
```