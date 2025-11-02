# LudaCRIS Installation Guide

LudaCRIS is an **AI-first, open-source Current Research Information System (CRIS)** designed to manage research metadata, vector embeddings, and graph relationships — fully locally and cloud-independent.

---

## Prerequisites

Before installing, make sure you have the following tools:

| Dependency | Version | Notes |
|-------------|----------|-------|
| **Docker** | ≥ 24.x | Required for all core services |
| **Docker Compose** | ≥ 2.21 | Manages the container stack |
| **Git** | ≥ 2.40 | Used for source control |
| **Python 3.11+** | Optional | For schema and ingestion scripts |
| **Make** | Optional | For command shortcuts (`make up`, `make down`, etc.) |

---

## Step 1 — Clone the Repository

```bash
git clone git@github.com:nveenstra/ludacris.git
cd ludacris
```

If you encounter SSH issues:

```bash
ssh -T git@github.com
```

This confirms your GitHub SSH key is active.

---

## Step 2 — Project Structure

```bash
bash init_dirs.sh
```

LudaCRIS keeps all persistent data and configuration inside the project folder.

```
ludacris/
├── docker-compose.yml
├── .env
├── README.md
├── INSTALL.md
└── volumes/
    ├── postgres/
    ├── opensearch/
    ├── neo4j/
    ├── redpanda/
    ├── n8n/
    └── ollama/
```

Each subdirectory under `volumes/` holds persistent storage for its corresponding service.

---

## Step 3 — Environment Configuration

Create or edit your `.env` file with the following defaults:

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ludacris
POSTGRES_DB=ludacris

NEO4J_AUTH=neo4j/ludacris123
OPENSEARCH_INITIAL_ADMIN_PASSWORD=ludacris123

OLLAMA_MODELS=/root/.ollama/models
```

> All passwords are local only — feel free to change them for production.

---

## Step 4 — Start the Stack

Bring up all services in detached mode:

```bash
docker compose up -d
```

Monitor logs as containers start:

```bash
docker compose logs -f
```

Check running containers:

```bash
docker ps
```

---

## Step 5 — Verify Components

| Service | URL / Port | Description |
|----------|-------------|-------------|
| **PostgreSQL** | `localhost:5432` | Core metadata + vector embeddings |
| **Neo4j Browser** | [http://localhost:7474](http://localhost:7474) | Graph layer for entities and relations |
| **OpenSearch** | [http://localhost:9200](http://localhost:9200) | Vector + full-text search engine |
| **OpenSearch Dashboards** | [http://localhost:5601](http://localhost:5601) | Visual search interface |
| **Redpanda Console** | [http://localhost:8083](http://localhost:8083) | Stream / CDC inspection |
| **Prefect UI** | [http://localhost:4200](http://localhost:4200) | Workflow orchestration dashboard |
| **n8n** | [http://localhost:5678](http://localhost:5678) | Agentic workflow and automation tool |
| **Ollama** | [http://localhost:11434](http://localhost:11434) | Local LLM backend |
| **OpenWebUI** | [http://localhost:3000](http://localhost:3000) | Chat-based user interface |
| **LudaCRIS API** | [http://localhost:8081/docs](http://localhost:8081/docs) | REST/GraphQL API (FastAPI backend) |
| **RAG Service** | [http://localhost:8082/docs](http://localhost:8082/docs) | Embedding + retrieval microservice |

---

## Step 6 — Initialize Database Schema

Load the database schema for the CRIS system:

```bash
psql -h localhost -U postgres -d ludacris -f schema.sql
```

Optionally, populate demo data for testing:

```bash
python scripts/seed_data.py
```

---

## Step 7 — Rebuild or Reset the Stack

Rebuild containers (after editing config or Dockerfiles):

```bash
docker compose build
docker compose up -d
```

Stop all containers:

```bash
docker compose down
```

Reset (remove all persistent data):

```bash
docker compose down -v
```

---

## Step 8 — Troubleshooting

| Symptom | Solution |
|----------|-----------|
| `neo4j password too short` | Ensure password ≥ 8 chars in `.env` |
| `Permission denied (publickey)` | Add or fix your SSH key on GitHub |
| Containers stuck on “Waiting” | View logs: `docker compose logs --tail=200 <service>` |
| `uvicorn: command not found` | Ensure Python base image includes `uvicorn` |
| `no GPUs found for Ollama` | Runs fine on CPU; enable CUDA only on Linux |
| OpenSearch fails to start | Ensure ≥ 2 GB RAM and permissions on `volumes/opensearch` |

---

## Step 9 — Security and Best Practices

- All services run locally by default — no external access required.  
- Never commit `.env` to version control.  
- Use stronger passwords in production.  
- For deployment, add `nginx` or `traefik` as a reverse proxy.  
- Regularly back up `volumes/` for persistence.

---

## Step 10 — Next Steps

1. **Ingest data** into PostgreSQL (projects, persons, publications, org units).  
2. **Enable CDC** through Debezium + Redpanda to propagate updates.  
3. **Index vectors** and full-texts in OpenSearch.  
4. **Link relationships** between entities in Neo4j.  
5. Use **OpenWebUI** to:  
   - Query data conversationally.  
   - Upload PDFs → trigger metadata extraction + embedding.  

---

## License

**LudaCRIS © 2025** — Open Source under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy  
of this software and associated documentation files (the “Software”), to deal  
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell  
copies of the Software, subject to the following conditions:  

The above copyright notice and this permission notice shall be included in  
all copies or substantial portions of the Software.  

**THE SOFTWARE IS PROVIDED “AS IS”**, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,  
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR  
PURPOSE AND NONINFRINGEMENT.
