#!/bin/bash

DIR="baseline_control"
CONFIG_FILE="$DIR/config_seed.txt"
FILE=$(find "$DIR" -maxdepth 2 -name "*_treemix.gz" | head -n 1)

[ -f "$CONFIG_FILE" ] || { echo "❌ No config.txt found."; exit 1; }
[ -f "$FILE" ] || { echo "❌ No _treemix.gz file found."; exit 1; }

PARAMS=$(cat "$CONFIG_FILE")
BASENAME=$(basename "$FILE" _treemix.gz)

for SEED in {1..10}; do
    OUT_PREFIX="${DIR}/${BASENAME}_seed${SEED}_output"
    echo "🚀 Running TreeMix on $FILE with seed $SEED"
    treemix -i "$FILE" -o "$OUT_PREFIX" -seed "$SEED" $PARAMS
done