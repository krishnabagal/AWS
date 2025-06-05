#!/bin/bash
BUCKET=$1
PREFIX=$2

# Fetch object versions and delete markers
VERSIONS_OUTPUT=$(aws s3api list-object-versions \
    --bucket "$BUCKET" \
    --prefix "$PREFIX" \
    --output json)

# Safely calculate number of items using `//[]` fallback
COUNT=$(echo "$VERSIONS_OUTPUT" | jq '[(.Versions // []), (.DeleteMarkers // [])] | add | length')

# Handle no objects found
if [ "$COUNT" -eq 0 ]; then
    echo "❌ No objects, versions, or delete markers found under prefix: '$PREFIX'"
    exit 1
fi

echo "⚠️  Found $COUNT objects/versions under '$PREFIX'. Proceeding to delete..."

# Build delete JSON and run deletion
echo "$VERSIONS_OUTPUT" | \
jq -c '{Objects: [(.Versions // []), (.DeleteMarkers // [])] | add | map({Key:.Key, VersionId:.VersionId})}' | \
while read -r DELETE_COMMAND; do
    if [ "$DELETE_COMMAND" != '{"Objects":[]}' ]; then
        aws s3api delete-objects \
            --bucket "$BUCKET" \
            --delete "$DELETE_COMMAND" \
            --no-cli-pager
    fi
done

echo "✅ All versions and delete markers under '$PREFIX' deleted successfully."
