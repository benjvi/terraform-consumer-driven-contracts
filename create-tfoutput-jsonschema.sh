#!/bin/bash
set -euo pipefail

# Print Usage and Exit
usage() {
  # >&2 will sent the output to STDERR not STDOUT
  cat >&2 <<- EOT

	Usage: $0 <-o TF OUTPUTS> 

        Creates a JSON schema mandating the presence of the specified Terraform outputs

            -o:                   JSON list of tf outputs that the schema should require 

	EOT
}

# This function process command line arguments to the script.
process_args() {
  # Reset OPTIND just in case this has run before
  OPTIND=1
  MODE=""
  # Learn about shell getopts by running "help getopts"

  while getopts "h?c:o:" opt ; do
    case "$opt" in
      h|\?) usage ; exit 0 ;;
      c) CONSUMER_NAME="$OPTARG" ;;
      o) CONSUMED_OUTPUTS="$OPTARG" ;;
      *)
	usage ; exit 2 ;;
    esac
  done
}

process_args "$@"

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
