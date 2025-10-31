# LudaCRIS — An Open, AI-First CRIS System

In the current political and economic climate, many universities are re-evaluating their approach to digital autonomy and sovereignty. Current Research Information Systems (CRIS) systems in conjunction with repositories were mainly used as tools to track research results. In recent years the need arose to integrate these systems into the Business Intelligence (BI) infrastructure in order to monitor research progress. 

At the same time, the rapid rise of AI-assisted workflows offers new opportunities to reduce the workload for researchers, analysts, and developers who build and maintain these systems. Existing commercial solutions are struggling to keep pace with this shift — both in terms of data complexity and openness. Reporting and showcasing functionality is shifting from the CRIS system to more suitable systems and even AI interfaces. This requires a rethink of the current landscape and a better infrastructure / platform to adapt to the fast changing world of research information management.

LudaCRIS aims to demonstrate a modern, AI-ready alternative:
a modular, open-source architecture designed to provide all core CRIS and BI functionality while enabling intelligent search, matching, classification and reasoning.

### Project Goals
	•	AI-First — importing, deduplication, semantic search, classification, reasoning, and automation are built in, not bolted on.
	•	Open Source Only — no proprietary dependencies or cloud lock-in.
	•	Locally Hosted — fully deployable on-premises for institutional sovereignty.
	•	Extensible and Adaptable — modular architecture that grows with your needs.

![Ludacris architecture](https://github.com/nveenstra/ludacris/blob/main/Ludacris.png)

### Architecture Overview

LudaCRIS is built as a modular, Docker-based architecture composed entirely of open-source and self-hostable components.
Each layer has a clear responsibility — from ingesting external data sources to reasoning over research information using AI.

The system is designed around the principles of transparency, extensibility, and local control.
At its core, it combines a PostgreSQL + pgvector lakehouse, a Neo4j knowledge graph, and OpenSearch for hybrid retrieval.
A RAG service orchestrates semantic retrieval and generation using locally hosted LLMs (Ollama or vLLM).

### Core Layers

| Layer | Purpose | Technologies |
|:------|:---------|:-------------|
| **Ingest Layer** | Collects and imports research metadata from external and internal sources such as Pure, Scopus, OpenAlex, or institutional repositories. | Python importers, REST APIs, scheduled jobs |
| **MCP Layer** | Orchestrates validation, normalization, and routing between services; enforces data contracts and workflows. | Prefect / n8n |
| **API Layer** | Exposes core services for search, linking, and embedding operations. | FastAPI |
| **Lakehouse (truth + history)** | Stores all CRIS entities with SCD2 history and embeddings (Bronze → Silver → Gold pipeline). | PostgreSQL + pgvector |
| **Message Bus** | Distributes incremental updates and change events to downstream components. | Redpanda + Debezium |
| **Full-Text Storage** | Provides hybrid keyword and semantic search for publications, datasets, and projects. | OpenSearch |
| **Knowledge Graph** | Captures relationships and supports reasoning and discovery across entities. | Neo4j Community |
| **LLM Server** | Generates embeddings and natural-language reasoning locally. | Ollama / vLLM |
| **RAG Service** | Performs retrieval-augmented generation by combining vector, keyword, and graph searches. | FastAPI + sentence-transformers |
| **User Interfaces** | Enables interaction for researchers and analysts through dashboards and chat interfaces. | OpenSearch Dashboards, LibreChat |

### Technology Stack Summary

| Component | Purpose | Technology / Tool |
|:-----------|:---------|:------------------|
| **Database & Lakehouse** | Primary data store with history (SCD2), vectors, and structured CRIS entities. | **PostgreSQL 16** with **pgvector** extension |
| **Knowledge Graph** | Relationship modeling and graph reasoning over entities (e.g., authors, projects, outputs). | **Neo4j Community Edition** |
| **Full-Text & Hybrid Search** | Keyword, BM25, and dense vector search; dashboard interface. | **OpenSearch** + **OpenSearch Dashboards** |
| **Workflow Orchestration** | ETL, data validation, and scheduled jobs for ingest and sync. | **Prefect** or **n8n** |
| **API Framework** | Exposes REST/GraphQL endpoints for search, linking, and embeddings. | **FastAPI** |
| **Message Bus / CDC** | Real-time propagation of changes to search and graph layers. | **Redpanda** + **Debezium** |
| **Embedding & Retrieval** | Generates and serves embeddings for entities and text chunks. | **sentence-transformers**, **pgvector**, **OpenSearch k-NN** |
| **RAG Service** | Combines hybrid retrieval (vector + keyword + graph) for grounded generation. | **FastAPI**, **Ollama**, **vLLM** |
| **LLM Runtime** | Local large language model host for inference and reasoning. | **Ollama** or **vLLM** |
| **User Interfaces** | Search dashboards, analytics, and conversational assistants. | **OpenSearch Dashboards**, **LibreChat** |
| **Containerization / Deployment** | Unified, reproducible local environment. | **Docker Compose** |
| **Programming Language** | Core implementation language for ETL, APIs, and services. | **Python 3.11+** |
| **Version Control** | Repository and collaboration. | **GitHub** |

### Flow architecture

Below is the full LudaCRIS architecture, including the RAG service and CDC data flows:

```mermaid
flowchart TB
  %% LudaCRIS – Architecture with RAG & CDC

  subgraph Docker
    direction TB

    %% ----- Top row -----
    subgraph Ingest["Ingest layer"]
      direction LR
      I1["Pure importer"]
      I2["Scopus importer"]
      I3["OpenAlex importer"]
      I4["Web scraper"]
    end

    subgraph Agents["Agents"]
      N8["n8n"]
    end

    subgraph UI["User interface"]
      OSD["OpenSearch Dashboards"]
      LC["LibreChat"]
    end

    subgraph RAGBOX["RAG service"]
      RAGAPI["/rag/answer • /rag/reindex"]
    end

    %% ----- Middle control plane -----
    subgraph MCP["MCP Layer"]
      MCPN["validation • routing • orchestration"]
    end

    subgraph API["API Layer (FastAPI)"]
      APIE["/search • /link • /embed"]
    end

    %% ----- Core stack -----
    subgraph Core["Core data & AI stack"]
      direction LR

      subgraph Lake["Lakehouse (truth + history)\nPostgreSQL + pgvector"]
        direction LR
        Bronze["Bronze"]
        Silver["Silver"]
        Gold["Gold (SCD2)"]
        Bronze --> Silver --> Gold
      end

      subgraph Bus["Message bus\nRedpanda + Debezium"]
      end

      subgraph LLM["LLM server\nOllama / vLLM"]
        EMB["Embedder"]
        REAS["Reasoner"]
      end
    end

    subgraph Fulltext["Full text storage"]
      OS["OpenSearch (BM25 + kNN)"]
    end

    subgraph Graph["Knowledge graph\nNeo4j community"]
      NEO["Neo4j"]
    end
  end

  %% ----- Control-plane connections -----
  Ingest --> MCP
  Agents --> MCP
  UI --> RAGBOX
  UI --> API
  RAGBOX --> API
  MCP --> API

  %% ----- CDC / data pipelines -----
  Gold -- CDC --> Bus
  Bus -- "index updates" --> OS
  Bus -- "graph sync" --> NEO
  Bus -- "re-embed jobs" --> EMB

  %% ----- Query-time RAG path -----
  API --> RAGAPI
  RAGAPI -- hybrid recall --> OS
  RAGAPI -- vector ANN --> Gold
  RAGAPI -- graph expand --> NEO
  RAGAPI -- generate --> REAS
  REAS --> RAGAPI
  RAGAPI --> API
  API --> UI

  %% Styles
  classDef layer fill:#f8f8ff,stroke:#777,stroke-width:1.2;
  classDef store fill:#f0fff4,stroke:#2b7,stroke-width:1.2;
  classDef svc fill:#eef7ff,stroke:#06c,stroke-width:1.2;
  classDef bus fill:#fff8e5,stroke:#b80,stroke-width:1.2;

  class Ingest,Agents,UI,RAGBOX,MCP,API layer;
  class Lake,Fulltext,Graph store;
  class Core,LLM,RAGAPI,APIE,MCPN,OS,NEO svc;
  class Bus bus;
