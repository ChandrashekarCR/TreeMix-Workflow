#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"               
CONFIG_FILE="config_m.txt"
MAX_RUNS=8
RUN_COUNT=0

# Choeck if the corresponding config file exists, else exit.
if [ ! -f "$CONFIG_FILE" ]; then
    echo "No config.txt found in $DIR"
    exit 1
else 
    echo "Config file exists"
fi

# Check if the treemix.gz file format is present, else exit
FILE=$(find "$PROJECT_ROOT" -type f -name "baseline_treemix.gz" | head -n 1)
if [ -z "$FILE" ]; then # -z checks if the string is empty
    echo "No input .gz file found in the project $PROJECT_ROOT"
    echo "Run the plink_script.sh to generate files for the baseline model."
    exit 1
else 
    echo "baseline_treemix.gz exists in $FILE"
fi

BASENAME=$(basename "$PROJECT_ROOT")
echo $BASENAME
PARAMS=$(cat "$CONFIG_FILE")

echo "Using config: $CONFIG_FILE"
echo "Using input file: $FILE"
echo "Running migrations 1 to 10 with max $MAX_RUNS jobs per instance"

# Check if there is a directory for storing appendix plots.
if [ ! -d $PROJECT_ROOT/plots/appendix/m_test ]; then \
    echo "No directory found."
    echo "Creating the directories."
    mkdir -p $PROJECT_ROOT/plots/appendix/m_test
else 
    echo "Directory already exists."
fi


for m in $(seq 1 15); do
    OUT_PREFIX="$PROJECT_ROOT/plots/appendix/m_test/baseline_m_${m}_output"
    LOCK_FILE="${OUT_PREFIX}.lock"

    if ls "${OUT_PREFIX}"* &> /dev/null; then
        echo "Output for m=$m exists. Skipping..."
        continue
    fi

    if [ -e "$LOCK_FILE" ]; then
        echo " Locked: m=$m is already running. Skipping..."s
        continue
    fi

    if [ "$RUN_COUNT" -ge "$MAX_RUNS" ]; then
        echo "Reached MAX_RUNS ($MAX_RUNS). Stopping."
        break
    fi

    echo "Running treemix m=$m..."
    touch "$LOCK_FILE"
    treemix -i "$FILE" $PARAMS -m "$m" -o "$OUT_PREFIX"
    rm -f "$LOCK_FILE"

    ((RUN_COUNT++))
done
