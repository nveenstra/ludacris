#!/usr/bin/env bash
# ==============================================
# LudaCRIS project bootstrap script
# Creates directory layout and permissions
# ==============================================

set -e

# --- base path (edit if needed)
BASE_DIR="${HOME}/Development/ludacris"

echo "Initializing LudaCRIS project at: $BASE_DIR"
mkdir -p "$BASE_DIR"

# --- data directories (for persistence)
DATA_DIRS=(
  data/postgres
  data/neo4j
  data/opensearch
  data/opensearch-logs
  data/redpanda
  data/prefect
  data/n8n
  data/openwebui
  data/repo        # CAS PDF repository
)

# --- other persistent volumes
MODELS_DIR=models   # Ollama models
SERVICES=(api rag-service)

# Create directory structure
for d in "${DATA_DIRS[@]}"; do
  mkdir -p "${BASE_DIR}/${d}"
done

for s in "${SERVICES[@]}"; do
  mkdir -p "${BASE_DIR}/${s}"
done

mkdir -p "${BASE_DIR}/${MODELS_DIR}"

# --- set ownership & permissions (cross-platform)
echo "Setting permissions..."

if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: group name usually "staff"
  USER_GROUP=$(id -gn "$USER")
  echo "Detected macOS → using group: $USER_GROUP"
  chown -R "$USER":"$USER_GROUP" "$BASE_DIR"
else
  # Linux or WSL: user and group typically identical
  chown -R "$USER":"$USER" "$BASE_DIR"
fi

chmod -R 755 "$BASE_DIR"

# --- .gitignore template
cat > "${BASE_DIR}/.gitignore" <<'EOF'
# LudaCRIS data and model directories (heavy, local)
data/
models/
__pycache__/
*.pyc
.env
.env.local
.ipynb_checkpoints/
EOF

# --- optional: print folder tree
echo
echo "Directory structure created:"
tree -L 2 "$BASE_DIR" || find "$BASE_DIR" -maxdepth 2 -type d

echo
echo "Done! You can now run 'docker compose up -d' in $BASE_DIR"
echo
echo "Your persistent data will live under:"
echo "  - PostgreSQL:      \$BASE_DIR/data/postgres"
echo "  - Neo4j:           \$BASE_DIR/data/neo4j"
echo "  - OpenSearch:      \$BASE_DIR/data/opensearch"
echo "  - PDF repository:  \$BASE_DIR/data/repo"
echo "  - Ollama models:   \$BASE_DIR/models"
echo