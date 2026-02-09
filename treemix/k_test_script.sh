#!/bin/bash

DIR="baseline"
CONFIG_FILE="$DIR/config_k.txt"
FILE=$(find "$DIR" -maxdepth 2 -name "*_treemix.gz" | head -n 1)

[ -f "$CONFIG_FILE" ] || { echo "❌ No config_k.txt found."; exit 1; }
[ -f "$FILE" ] || { echo "❌ No _treemix.gz file found."; exit 1; }

PARAMS=$(cat "$CONFIG_FILE")
BASENAME=$(basename "$FILE" _treemix.gz)

for k in 200 500 1000 1500 2000 10000; do
    OUT_PREFIX="${DIR}/${BASENAME}_k${k}_output"
    echo "🚀 Running TreeMix on $FILE with k = $k"
    treemix -i "$FILE" -o "$OUT_PREFIX" -k "$k" $PARAMS
done