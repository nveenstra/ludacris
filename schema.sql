-- LudaCRIS PostgreSQL Schema (fixed pass)
-- AI-first CRIS with vectors (pgvector), graph-friendly relations, and CDC-ready tables
-- Load with:  psql -h localhost -U postgres -d ludacris -f schema.sql

-- =============================
-- Extensions
-- =============================
CREATE EXTENSION IF NOT EXISTS pgcrypto;       -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pg_trgm;        -- trigram indexes for fuzzy text search
CREATE EXTENSION IF NOT EXISTS vector;         -- pgvector
CREATE EXTENSION IF NOT EXISTS postgis;        -- geometry(Point,4326)

-- =============================
-- Helper enums
-- =============================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'output_type') THEN
    CREATE TYPE output_type AS ENUM (
      'article','book','chapter','conference_paper','dataset','software',
      'preprint','working_paper','discussion_paper','report','thesis',
      'review','poster','abstract','editorial','book_chapter','case_note','other'
    );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'doc_source') THEN
    CREATE TYPE doc_source AS ENUM ('upload','harvest','url');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'project_status') THEN
    CREATE TYPE project_status AS ENUM ('planned','active','completed','on_hold','cancelled');
  END IF;
END $$;

-- =============================
-- Core entities
-- =============================

-- Organisations (units, departments, institutions)
CREATE TABLE IF NOT EXISTS organisation (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id       UUID REFERENCES organisation(id) ON DELETE SET NULL,
  name            TEXT NOT NULL,
  type            TEXT,                            -- e.g., university, faculty, department, institute
  country         TEXT,
  website         TEXT,
  persistent_ids  JSONB NOT NULL DEFAULT '{}'::jsonb,   -- { "ror": "...", "grid": "...", ... }
  keywords        JSONB NOT NULL DEFAULT '[]'::jsonb,
  location        geometry(Point, 4326),                -- lon/lat (WGS84)
  lat             DOUBLE PRECISION
                    GENERATED ALWAYS AS (CASE WHEN location IS NULL THEN NULL ELSE ST_Y(location) END) STORED,
  lon             DOUBLE PRECISION
                    GENERATED ALWAYS AS (CASE WHEN location IS NULL THEN NULL ELSE ST_X(location) END) STORED,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT organisation_persistent_ids_is_object
    CHECK (jsonb_typeof(persistent_ids) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_organisation_name_trgm
  ON organisation USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_organisation_persistent_ids
  ON organisation USING gin (persistent_ids);
CREATE INDEX IF NOT EXISTS idx_organisation_location_gix
  ON organisation USING gist (location);

-- Persons (researchers, staff)
CREATE TABLE IF NOT EXISTS person (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  given_name      TEXT NOT NULL,
  family_name     TEXT NOT NULL,
  orcid           TEXT UNIQUE,                        -- nullable but unique if present
  persistent_ids  JSONB NOT NULL DEFAULT '{}'::jsonb, -- { "scopus": "...", "pure": "...", ... }
  affiliations    JSONB NOT NULL DEFAULT '[]'::jsonb, -- [{ "org_id": "...", "role": "...", ... }]
  bio             TEXT,
  keywords        JSONB NOT NULL DEFAULT '[]'::jsonb, -- [{ "term": "...", "scheme": "...", "code": "..." }, ...]
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- JSON structure validation
  CONSTRAINT person_persistent_ids_is_object
    CHECK (jsonb_typeof(persistent_ids) = 'object'),
  CONSTRAINT person_affiliations_is_array
    CHECK (jsonb_typeof(affiliations) = 'array'),
  CONSTRAINT person_affiliations_all_objects
    CHECK (NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(affiliations) e
      WHERE jsonb_typeof(e) <> 'object'
    )),
  CONSTRAINT person_keywords_is_array
    CHECK (jsonb_typeof(keywords) = 'array'),
  CONSTRAINT person_keywords_all_objects
    CHECK (NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(keywords) e
      WHERE jsonb_typeof(e) <> 'object'
    )),
  CONSTRAINT person_keywords_require_term
    CHECK (NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(keywords) e
      WHERE NOT (e ? 'term') OR jsonb_typeof(e->'term') <> 'string'
    ))
);

CREATE INDEX IF NOT EXISTS idx_person_name_trgm
  ON person USING gin ((given_name || ' ' || family_name) gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_person_persistent_ids
  ON person USING gin (persistent_ids);
CREATE INDEX IF NOT EXISTS idx_person_affiliations_gin
  ON person USING gin (affiliations);
CREATE INDEX IF NOT EXISTS idx_person_keywords_gin
  ON person USING gin (keywords);

-- Projects
CREATE TABLE IF NOT EXISTS project (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  abstract        TEXT,
  start_date      DATE,
  end_date        DATE,
  status          project_status DEFAULT 'planned',
  lead_org_id     UUID REFERENCES organisation(id) ON DELETE SET NULL,
  pi_person_id    UUID REFERENCES person(id) ON DELETE SET NULL,
  persistent_ids  JSONB NOT NULL DEFAULT '{}'::jsonb,
  keywords        JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_project_title_trgm
  ON project USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_project_persistent_ids
  ON project USING gin (persistent_ids);

-- Research outputs (publications, datasets, software, ...)
CREATE TABLE IF NOT EXISTS output (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title             TEXT NOT NULL,
  subtitle          TEXT,
  type              output_type NOT NULL DEFAULT 'article',
  doi               TEXT,
  publication_year  INT,
  abstract          TEXT,
  keywords          JSONB NOT NULL DEFAULT '[]'::jsonb,
  affiliated_org_id UUID REFERENCES organisation(id) ON DELETE SET NULL,
  persistent_ids    JSONB NOT NULL DEFAULT '{}'::jsonb,   -- { "scopus": "...", "pure": "...", "openalex": "..." }
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (doi) DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX IF NOT EXISTS idx_output_title_trgm
  ON output USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_output_persistent_ids
  ON output USING gin (persistent_ids);

-- Funders and awards
CREATE TABLE IF NOT EXISTS funder (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  country       TEXT,
  external_ids  JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_funder_name_trgm
  ON funder USING gin (name gin_trgm_ops);

CREATE TABLE IF NOT EXISTS funding_award (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  funder_id        UUID NOT NULL REFERENCES funder(id) ON DELETE CASCADE,
  project_id       UUID NOT NULL REFERENCES project(id) ON DELETE CASCADE,
  award_identifier TEXT,                       -- grant number
  amount           NUMERIC(20,2),
  currency         CHAR(3),
  start_date       DATE,
  end_date         DATE,
  call_identifier  TEXT,
  external_ids     JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (funder_id, project_id, award_identifier)
);

-- Authorship / participation junctions
CREATE TABLE IF NOT EXISTS person_output (
  person_id   UUID REFERENCES person(id) ON DELETE CASCADE,
  output_id   UUID REFERENCES output(id) ON DELETE CASCADE,
  role        TEXT,              -- e.g., author, editor, maintainer
  position    INT,               -- author order
  PRIMARY KEY (person_id, output_id)
);

CREATE TABLE IF NOT EXISTS person_project (
  person_id   UUID REFERENCES person(id) ON DELETE CASCADE,
  project_id  UUID REFERENCES project(id) ON DELETE CASCADE,
  role        TEXT,              -- e.g., PI, Co-PI, researcher
  start_date  DATE,
  end_date    DATE,
  PRIMARY KEY (person_id, project_id)
);

CREATE TABLE IF NOT EXISTS output_project (
  output_id   UUID REFERENCES output(id) ON DELETE CASCADE,
  project_id  UUID REFERENCES project(id) ON DELETE CASCADE,
  PRIMARY KEY (output_id, project_id)
);

CREATE TABLE IF NOT EXISTS output_organisation (
  output_id        UUID REFERENCES output(id) ON DELETE CASCADE,
  organisation_id  UUID REFERENCES organisation(id) ON DELETE CASCADE,
  PRIMARY KEY (output_id, organisation_id)
);

CREATE TABLE IF NOT EXISTS output_funding_award (
  output_id        UUID REFERENCES output(id) ON DELETE CASCADE,
  funding_award_id UUID REFERENCES funding_award(id) ON DELETE CASCADE,
  PRIMARY KEY (output_id, funding_award_id)
);

-- =============================
-- Documents & Full-text pointers
-- =============================
CREATE TABLE IF NOT EXISTS document (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  output_id     UUID REFERENCES output(id) ON DELETE SET NULL,
  sha256_hex    CHAR(64) UNIQUE,            -- content-addressed storage key
  path          TEXT NOT NULL,              -- absolute or repo-relative path to file on disk
  mime_type     TEXT,
  byte_size     BIGINT,
  source        doc_source NOT NULL DEFAULT 'upload',
  metadata      JSONB NOT NULL DEFAULT '{}'::jsonb,  -- extracted metadata (title, authors, etc.)
  text_preview  TEXT,                       -- optional short preview; full text goes to OpenSearch
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_document_path ON document (path);
CREATE INDEX IF NOT EXISTS idx_document_metadata_gin ON document USING gin (metadata);

-- =============================
-- Embeddings (pgvector)
-- =============================
-- Use 768 dims by default (e.g., E5-large). Adjust if you standardize on another model.
CREATE TABLE IF NOT EXISTS embedding (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_type    TEXT NOT NULL CHECK (owner_type IN ('person','organisation','project','output','document')),
  owner_id      UUID NOT NULL,
  model         TEXT NOT NULL,              -- e.g., intfloat/e5-large, bge-small, etc.
  dimension     INT  NOT NULL DEFAULT 768,
  vector        VECTOR(768) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (owner_type, owner_id, model)
);

CREATE INDEX IF NOT EXISTS idx_embedding_model ON embedding (model);
-- Optional HNSW (pgvector >= 0.5.0 + Postgres 15+)
-- CREATE INDEX IF NOT EXISTS idx_embedding_hnsw ON embedding USING hnsw (vector);

-- =============================
-- Generic typed relations (graph-friendly)
-- =============================
CREATE TABLE IF NOT EXISTS relation (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  src_type      TEXT NOT NULL CHECK (src_type IN ('person','organisation','project','output','document')),
  src_id        UUID NOT NULL,
  dst_type      TEXT NOT NULL CHECK (dst_type IN ('person','organisation','project','output','document')),
  dst_id        UUID NOT NULL,
  relation_type TEXT NOT NULL,              -- e.g., "affiliated_with", "works_on", "cites", "is_part_of"
  properties    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (src_type, src_id, dst_type, dst_id, relation_type)
);

CREATE INDEX IF NOT EXISTS idx_relation_src ON relation (src_type, src_id);
CREATE INDEX IF NOT EXISTS idx_relation_dst ON relation (dst_type, dst_id);

-- =============================
-- Event log / Outbox (CDC friendly)
-- =============================
CREATE TABLE IF NOT EXISTS event_log (
  id              BIGSERIAL PRIMARY KEY,
  event_time      TIMESTAMPTZ NOT NULL DEFAULT now(),
  aggregate_type  TEXT NOT NULL,         -- table/entity name
  aggregate_id    UUID NOT NULL,
  event_type      TEXT NOT NULL,         -- created/updated/deleted/ingested/indexed/etc.
  source          TEXT,                  -- e.g., "api", "ingester", "n8n"
  payload         JSONB NOT NULL DEFAULT '{}'::jsonb,
  trace_id        TEXT
);

CREATE INDEX IF NOT EXISTS idx_event_log_time ON event_log (event_time);
CREATE INDEX IF NOT EXISTS idx_event_log_aggregate ON event_log (aggregate_type, aggregate_id);

-- =============================
-- Timestamps update trigger
-- =============================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_organisation') THEN
    CREATE TRIGGER set_updated_at_organisation BEFORE UPDATE ON organisation FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_person') THEN
    CREATE TRIGGER set_updated_at_person BEFORE UPDATE ON person FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_project') THEN
    CREATE TRIGGER set_updated_at_project BEFORE UPDATE ON project FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_output') THEN
    CREATE TRIGGER set_updated_at_output BEFORE UPDATE ON output FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_document') THEN
    CREATE TRIGGER set_updated_at_document BEFORE UPDATE ON document FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;

-- Convenience view
CREATE OR REPLACE VIEW v_output_authors AS
SELECT
  o.id   AS output_id,
  o.title,
  p.id   AS person_id,
  p.given_name,
  p.family_name,
  po.position
FROM output o
JOIN person_output po ON po.output_id = o.id
JOIN person p ON p.id = po.person_id
ORDER BY o.id, po.position;