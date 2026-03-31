# Laboratorio de Monitoreo — Sistemas Distribuidos UPTC

## Arquitectura implementada

```
HOST
├── nginx (puerto 80 expuesto)       ← balanceador de carga
│   └── app x3 réplicas             ← Spring Boot :8080
│       └── db (PostgreSQL)         ← red interna backend
│
└── Monitoreo (red monitoring)
    ├── Prometheus :9090             ← recolecta métricas
    ├── Grafana :3000                ← dashboards
    ├── Alertmanager                 ← envía alertas a Telegram
    ├── cAdvisor                     ← métricas de contenedores
    ├── node_exporter                ← métricas del host
    └── postgres_exporter            ← métricas de PostgreSQL
```
