#!/bin/bash
set -euo pipefail

# inputs
CONSUMER_NAME="consumer2"
CONSUMED_OUTPUTS='[ "azs", "region", "banana" ]'

# schema components
SCHEMA_REQUIRED_FIELD="{ \"required\": $CONSUMED_OUTPUTS }"
SCHEMA_PROPERTIES_FIELD="$(echo $CONSUMED_OUTPUTS |  jq '{ properties: (map({ (.) : { "$ref": "#/definitions/tf_output" } }) | add)}')"
SCHEMA_STUB=$(cat <<SETVAR
{
  "definitions": {
    "tf_output": {
      "type": "object",
      "properties": {
        "type": { "type": "string" },
        "value": {
          "anyOf": [
            {"type": "string" },
            {"type": "array" },
            {"type": "object" }
          ]
        }
      },
      "required": ["type"]
    }
  },
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object"
}
SETVAR
)

SCHEMA="$SCHEMA_STUB"
SCHEMA+=$(printf "\n$SCHEMA_REQUIRED_FIELD")
SCHEMA+=$(printf "\n$SCHEMA_PROPERTIES_FIELD")
SCHEMA="$(echo $SCHEMA | jq -s 'add')"

echo "$SCHEMA"
echo "$SCHEMA" > tfoutput-jsonschema-$CONSUMER_NAME.json
echo "JSON schema written to: tfoutput-jsonschema-$CONSUMER_NAME.json"

