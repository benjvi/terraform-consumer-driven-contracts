#!/bin/bash
set -euo pipefail

CONSUMER_NAME="consumer2"
TFOUTPUT_FILE="tfoutput.json"

SCHEMA_FILE="tfoutput-jsonschema-$CONSUMER_NAME.json"
jsonschema -i "$TFOUTPUT_FILE" "$SCHEMA_FILE"
