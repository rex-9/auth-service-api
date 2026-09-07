#!/usr/bin/env bash
# ==============================================================================
# rexone-core/scripts/prod_garage_init.sh
# Production & UAT Garage S3 Cluster Layout & Bucket Initialization Script
# ==============================================================================
set -euo pipefail

CONTAINER_NAME="${1:-${GARAGE_CONTAINER_NAME:-rexone-garage}}"
BUCKET_NAME="${2:-${S3_BUCKET:-rexone}}"
KEY_NAME="${3:-${GARAGE_KEY_NAME:-rexone-key}}"

echo "=================================================================="
echo "🚀 Initializing Garage S3 Cluster on: $CONTAINER_NAME"
echo "   Bucket: $BUCKET_NAME | Key Name: $KEY_NAME"
echo "=================================================================="

# 1. Wait for container to respond
echo "--> Checking Garage status..."
READY=false
for i in {1..30}; do
  if docker exec "$CONTAINER_NAME" /garage status >/dev/null 2>&1; then
    READY=true
    break
  fi
  echo "    Waiting for $CONTAINER_NAME to boot ($i/30)..."
  sleep 2
done

if [ "$READY" = "false" ]; then
  echo "❌ Error: $CONTAINER_NAME is not responding after 60 seconds."
  exit 1
fi

# 2. Assign cluster layout if node is unassigned
STATUS=$(docker exec "$CONTAINER_NAME" /garage status 2>/dev/null || true)
if echo "$STATUS" | grep -q "NO ROLE ASSIGNED"; then
  NODE_ID=$(echo "$STATUS" | grep "NO ROLE ASSIGNED" | awk '{print $1}')
  echo "--> Assigning cluster layout for node $NODE_ID..."
  docker exec "$CONTAINER_NAME" /garage layout assign -z dc1 -c 1G "$NODE_ID"
  docker exec "$CONTAINER_NAME" /garage layout apply --version 1
  echo "    ✓ Cluster layout applied successfully."
else
  echo "    ✓ Cluster layout already configured."
fi

# 3. Create bucket if missing
if ! docker exec "$CONTAINER_NAME" /garage bucket info "$BUCKET_NAME" >/dev/null 2>&1; then
  echo "--> Creating bucket '$BUCKET_NAME'..."
  docker exec "$CONTAINER_NAME" /garage bucket create "$BUCKET_NAME"
  echo "    ✓ Bucket '$BUCKET_NAME' created."
else
  echo "    ✓ Bucket '$BUCKET_NAME' already exists."
fi

# 4. Import or create S3 API Key
if ! docker exec "$CONTAINER_NAME" /garage key info "$KEY_NAME" >/dev/null 2>&1; then
  if [ -n "${S3_ACCESS_KEY:-}" ] && [ -n "${S3_SECRET_KEY:-}" ]; then
    echo "--> Importing S3 key '$KEY_NAME' from environment..."
    docker exec "$CONTAINER_NAME" /garage key import -n "$KEY_NAME" "$S3_ACCESS_KEY" "$S3_SECRET_KEY" --yes
    echo "    ✓ S3 key '$KEY_NAME' imported."
  else
    echo "--> Generating new S3 key '$KEY_NAME'..."
    KEY_OUTPUT=$(docker exec "$CONTAINER_NAME" /garage key create "$KEY_NAME")
    GEN_KEY=$(echo "$KEY_OUTPUT" | grep "Key ID:" | awk '{print $3}')
    GEN_SECRET=$(echo "$KEY_OUTPUT" | grep "Secret key:" | awk '{print $3}')
    echo "------------------------------------------------------------------"
    echo "⚠️ S3 Key Generated! Add these to your Coolify environment variables:"
    echo "S3_ACCESS_KEY=$GEN_KEY"
    echo "S3_SECRET_KEY=$GEN_SECRET"
    echo "------------------------------------------------------------------"
  fi
else
  echo "    ✓ S3 key '$KEY_NAME' exists."
fi

# 5. Grant bucket permissions to the key
echo "--> Granting read/write/owner permissions to key '$KEY_NAME' on bucket '$BUCKET_NAME'..."
docker exec "$CONTAINER_NAME" /garage bucket allow --read --write --owner "$BUCKET_NAME" --key "$KEY_NAME"
echo "    ✓ Permissions assigned."

echo "=================================================================="
echo "✅ Garage S3 setup complete for $CONTAINER_NAME!"
echo "=================================================================="
