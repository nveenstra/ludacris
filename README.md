# LudaCRIS — Toward a 4th Generation of Research Information Systems

The landscape in which research information systems operate is rapidly changing. Current Research Information Systems (CRIS) systems in conjunction with repositories were mainly used as standalone tools to track research results. In recent years the need arose to integrate these systems into the Business Intelligence (BI) infrastructure in order to monitor research progress. 

At the same time, the rapid rise of AI-assisted workflows offers new opportunities to reduce the workload for researchers, analysts, and developers who use, build and maintain these systems. Existing commercial solutions are struggling to keep pace with this shift — both in terms of data complexity and openness. Reporting and showcasing functionality is shifting from the CRIS system to more suitable systems and even AI interfaces. This requires a rethink of the current landscape and a better infrastructure / platform to adapt to the fast changing world of research information management. In the current political and economic climate, many universities are also re-evaluating their approach to digital autonomy and sovereignty. 

LudaCRIS aims to demonstrate a modern, AI-ready alternative:
a modular, open-source architecture designed to provide all core CRIS and BI functionality while enabling automated ingestion of new data, intelligent search, matching, classification and reasoning.



### Evolution of CRIS Generations (Context)

| Generation | Era | Characteristics | Examples / Technologies |
|:------------|:----|:----------------|:-------------------------|
| **1st Gen — Administrative CRIS** | 1980s–1990s | Institutional record-keeping; closed databases; manually curated; limited interoperability. | In-house systems, Oracle DBs, Excel-based tracking. |
| **2nd Gen — Integrated CRIS** | 2000s–2010s | Commercial, monolithic platforms; metadata aggregation; integration with repositories; reporting and compliance focus. | Pure, Converis, Symplectic Elements. |
| **3rd Gen — Open & Interoperable CRIS** | 2010s–2020s | Open standards (CERIF, RIOXX, Schema.org); APIs; interoperability with repositories and funders; partial open-source ecosystems. | DSpace-CRIS, openCRIS initiatives, VIVO. |
| **4th Gen — Data Intelligence CRIS** | Emerging 2020s | AI-assisted, event-driven, graph-oriented architectures; open and locally hostable; built around embeddings, reasoning, and automation. | → **LudaCRIS** |

LudaCRIS can be seen as a fourth-generation CRIS system, designed for the era of data intelligence and digital sovereignty.
It builds upon open standards and institutional autonomy, extending the traditional CRIS model with vectorized data, knowledge graphs, and locally hosted AI components for reasoning and automation.
Where earlier CRIS systems focused on metadata aggregation and reporting, LudaCRIS enables semantic understanding, contextual discovery, and AI-assisted research information management.



### Project Goals
	•	AI-First — importing, deduplication, semantic search, classification, reasoning, and automation are built in, not bolted on.
	•	Open Source Only — no proprietary dependencies or cloud lock-in.
	•	Locally Hosted — fully deployable on-premises for institutional sovereignty.
	•	Extensible and Adaptable — modular architecture that grows with your needs.
	•	Chat only interface — reduce the overhead of front-end development changes and focus on AI interaction for queries, visualisations and data import- and export.
	


### Architecture Overview

The figure below illustrates the modular LudaCRIS architecture.
Data flows from the ingest layer through orchestrated Prefect pipelines into the Lakehouse, where versioned records are stored and embedded.
CDC events are propagated via Redpanda to update the Knowledge Graph, Full-Text index, and LLM embeddings.
A Retrieval-Augmented Generation (RAG) service unifies these components, enabling natural-language reasoning over verified institutional data sources.

![Ludacris architecture](https://github.com/nveenstra/ludacris/blob/main/Ludacris.png)

LudaCRIS is built as a modular, Docker-based architecture composed entirely of open-source and self-hostable components.
Each layer has a clear responsibility — from ingesting external data sources to reasoning over research information using AI.

The system is designed around the principles of transparency, extensibility, and local control.
At its core, it combines a PostgreSQL + pgvector lakehouse, a Neo4j knowledge graph, and OpenSearch for hybrid retrieval.
A RAG service orchestrates semantic retrieval and generation using locally hosted LLMs (Ollama or vLLM).



### Core Layers

| Layer | Purpose | Technologies |
|:------|:--------|:-------------|
| **Ingest Layer** | Collects and imports research metadata from external and internal sources (Pure, Scopus, OpenAlex, repositories, scrapers). | Python importers, REST APIs, scheduled jobs |
| **Agents** | Handles automation, event triggers, and human-in-the-loop workflows. | n8n |
| **MCP Layer** | Bridges the API and internal services via the Model Context Protocol, exposing institutional data and tools to local LLMs. | FastMCP |
| **API Layer** | Exposes structured CRIS data, search endpoints, and LLM integration. | FastAPI |
| **Lakehouse (truth + history)** | Stores CRIS entities with SCD2 history and embeddings (Bronze → Silver → Gold pipeline). | PostgreSQL + pgvector, Prefect, Great Expectations |
| **Message Bus** | Propagates CDC events between Lakehouse, Graph, Search, and LLM components for real-time updates. | Redpanda + Debezium |
| **LLM Server** | Hosts local models for embeddings and reasoning. | Ollama / vLLM |
| **Knowledge Graph** | Captures relationships for reasoning and discovery. | Neo4j Community |
| **Full-Text Storage** | Hybrid keyword and semantic search for documents and metadata. | OpenSearch |
| **RAG Service** | Combines retrieval from the Lakehouse, Graph, and Search layers for grounded generation. | FastAPI, sentence-transformers, Ollama |
| **User Interface** | Dashboards and conversational UI for researchers and analysts. | OpenSearch Dashboards, LibreChat |



### Technology Stack Summary

| Component | Purpose | Technology / Tool |
|:-----------|:--------|:------------------|
| **Database & Lakehouse** | SCD2 entities, vectors, and authoritative CRIS store. | PostgreSQL 16 + pgvector |
| **Knowledge Graph** | Graph reasoning over entities and relationships. | Neo4j Community |
| **Full-Text & Hybrid Search** | BM25 + k-NN with dashboards. | OpenSearch + OpenSearch Dashboards |
| **Orchestration & Validation** | Dataflows, scheduling, and quality checks. | Prefect + Great Expectations |
| **Automation / Agents** | Event-driven workflows and human-in-loop actions. | n8n |
| **MCP Layer** | Connects LLMs and local APIs through Model Context Protocol. | FastMCP |
| **API Framework** | Exposes REST and GraphQL endpoints. | FastAPI |
| **Message Bus / CDC** | Propagates changes between stores and services. | Redpanda + Debezium |
| **Embeddings & Retrieval** | Text and metadata embeddings with vector search. | sentence-transformers, pgvector, OpenSearch k-NN |
| **RAG Service** | Retrieval-augmented generation with grounded responses. | FastAPI, Ollama / vLLM |
| **LLM Runtime** | Local model execution for embedding and reasoning. | Ollama / vLLM |
| **User Interfaces** | Search dashboards and chat UI. | OpenSearch Dashboards, LibreChat |
| **Containerization / Deployment** | Local, reproducible architecture. | Docker Compose |
| **Programming Language** | Core implementation. | Python 3.11+ |
| **Version Control** | Repository and collaboration. | GitHub |



### Chat only interface

Developing a modern frontend for this system would mean considerable development time and maintenance in order to adapt to new standards and functionality. At the same time users are rapidly adapting to using AI bot chats to retrieve information. So rather than going into the complexity of designing and maintaining a user interface suited for multiple platforms and devices, LudaCRIS relies on a chat interface that can be used for all tasks required. 

| Capability | Why It Matters in LudaCRIS |
|:------------|:---------------------------|
| **Conversational interface** | Enables natural-language access to research data through the RAG service. |
| **File upload / PDF ingestion** | Allows users to add new publications or datasets directly via chat, automatically extracting and storing metadata in the CRIS. |
| **Structured query generation** | Translates natural-language questions into SQL or graph queries to explore data programmatically. |
| **Visualization** | Displays dynamic co-author graphs, project networks, and analytical trends inside the chat interface. |
| **Tool calling / API integration** | Lets the chat interface trigger backend actions such as “create record” or “update metadata.” |
| **Authentication / roles** | Restricts sensitive actions to authorized users (e.g., librarians, admins). |
| **Local + open source** | Ensures full institutional data sovereignty and offline capability—no cloud dependencies. |



### Flow architecture

Below is an example of the RAG service and CDC data flows:

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
      LC["Open WebUI"]
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


This project is aimed at delivering a proof of concept. I am working on this in my spare time, so it will take some time. Interested in collaborating / brainstorming? DM me on linkedin. 
