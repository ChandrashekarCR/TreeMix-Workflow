#!/bin/bash

DIR="baseline/"                 # Passe diesen Pfad an, falls nötig
CONFIG_FILE="${DIR}config_m.txt"
MAX_RUNS=4
RUN_COUNT=0

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ No config.txt found in $DIR"
    exit 1
fi

FILE=$(find "$DIR" -maxdepth 2 -name "*_treemix.gz" | head -n 1)
if [ -z "$FILE" ]; then
    echo "❌ No input .gz file found in $DIR"
    exit 1
fi

BASENAME=$(basename "$DIR")
PARAMS=$(cat "$CONFIG_FILE")

echo "📂 Using config: $CONFIG_FILE"
echo "📄 Using input file: $FILE"
echo "🔢 Running migrations 1 to 10 with max $MAX_RUNS jobs per instance"

for m in $(seq 1 10); do
    OUT_PREFIX="${DIR}${BASENAME}_m_${m}_output"
    LOCK_FILE="${OUT_PREFIX}.lock"

    if ls "${OUT_PREFIX}"* &> /dev/null; then
        echo "  ⚠️ Output for m=$m exists. Skipping..."
        continue
    fi

    if [ -e "$LOCK_FILE" ]; then
        echo "  🔒 Locked: m=$m is already running. Skipping..."
        continue
    fi

    if [ "$RUN_COUNT" -ge "$MAX_RUNS" ]; then
        echo "  🚫 Reached MAX_RUNS ($MAX_RUNS). Stopping."
        break
    fi

    echo "  🚀 Running treemix m=$m..."
    touch "$LOCK_FILE"
    treemix -i "$FILE" $PARAMS -m "$m" -o "$OUT_PREFIX"
    rm -f "$LOCK_FILE"

    ((RUN_COUNT++))
done
