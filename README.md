# ludacris
Open AI ready CRIS system 

![Ludacris architecture](https://github.com/nveenstra/ludacris/blob/main/Ludacris.png)


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
