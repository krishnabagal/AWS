#!/bin/bash
set -e
BUCKET=$1
PREFIX=$2

# Step 1: Get all versions and delete markers
aws s3api list-object-versions \
    --bucket "$BUCKET" \
    --prefix "$PREFIX" \
    --output json > versions.json

# Step 2: Extract all keys + version IDs
jq -c '[(.Versions // []), (.DeleteMarkers // [])] | add | map({Key: .Key, VersionId: .VersionId})' versions.json > all_objects.json

# Step 3: Split into batches of 1000 objects
jq -c '.[]' all_objects.json | split -l 100 - delete_batch_

# Step 4: Loop through each batch and delete
for file in delete_batch_*; do
    BATCH_JSON=$(jq -s '{Objects: .}' "$file")
    aws s3api delete-objects \
        --bucket "$BUCKET" \
        --delete "$BATCH_JSON" \
        --no-cli-pager
    echo "✅ Deleted batch: $file"
    rm "$file"
done

# Cleanup
rm versions.json all_objects.json

echo "🎉 All versions and delete markers under '$PREFIX' deleted successfully."
