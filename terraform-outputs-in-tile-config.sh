#!/bin/bash
set -euo pipefail

# Print Usage and Exit
usage() {
  # >&2 will sent the output to STDERR not STDOUT
  cat >&2 <<- EOT

	Usage: $0 <-o TFOUTPUT_FILE> <-c TILE_CONFIG_FILE> [-u]

        Outputs Teraform outputs that are in use in the specified config file

	    -o:                    Terraform output file
            -c:                    Tile config file, or any other file using bosh interpolation
            -u:                    Show unused terraform outputs (opposite of default behaviour)


	EOT
}

# This function process command line arguments to the script.
process_args() {
  # Reset OPTIND just in case this has run before
  OPTIND=1
  MODE=""
  # Learn about shell getopts by running "help getopts"

  while getopts "h?o:t:u" opt ; do
    case "$opt" in
      h|\?) usage ; exit 0 ;;
      o) TFOUTPUT_FILE="$OPTARG" ;;
      t) TILE_CONFIG_FILE="$OPTARG" ;;
      u) UNUSED_MODE=true ;; 
      *)
	usage ; exit 2 ;;
    esac
  done
}

UNUSED_MODE=false
process_args "$@"

# expect bosh int to fail so must be able to continue
set +e
# getting all the vars the tile config file has
# very hacky to depend on the error message formatting
# there must be a better way...
TILE_VARS_LIST="$(bosh int $TILE_CONFIG_FILE --var-errs 2>&1 | sed '$d; 1d' | sed '$d' | tr -d ' -' | sort)"
set -e
TFOUTPUTS_LIST="$(cat $TFOUTPUT_FILE | jq -r 'keys[]' | sort)"

CONSUMED_OUTPUTS=$(comm -12 <( echo "$TFOUTPUTS_LIST" ) <( echo "$TILE_VARS_LIST" ) | xargs printf "\"%s\"\n" | jq -s .)
UNUSED_OUTPUTS=$(comm -23 <( echo "$TFOUTPUTS_LIST" ) <( echo "$TILE_VARS_LIST" ) | xargs printf "\"%s\"\n" | jq -s .)

if [ "$UNUSED_MODE" = true ]; then
  printf "$UNUSED_OUTPUTS\n"
else
  printf "$CONSUMED_OUTPUTS\n"
fi
