#!/bin/sh

TIMEOUT=15
QUIET=0
CURLPATH=''
HEADER=''

echoerr() {
  if [ "$QUIET" -ne 1 ]; then printf "%s\n" "$*" 1>&2; fi
}

usage() {
  exitcode="$1"
  cat << USAGE >&2
Usage:
  $cmdname host:port [-u curlpath] [-h header] [-t timeout] [-- command args]
  -u curlpath                         Path to curl for test
  -h header                           Header to curl for test
  -q | --quiet                        Do not output any status messages
  -t TIMEOUT | --timeout=timeout      Timeout in seconds, zero for no timeout
  -- COMMAND ARGS                     Execute command with args after the test finishes
USAGE
  exit "$exitcode"
}

wait_for() {
  for i in `seq $TIMEOUT` ; do
    if [ "$(which nc)" = "" ]; then
        echo >&2 "ERR: nc command not found"
        exit 1
    fi
    nc -z "$HOST" "$PORT" > /dev/null 2>&1
    
    result=$?
    if [ $result -eq 0 ] ; then
      if [ $# -gt 0 ] ; then
        exec "$@"
      fi

      if [ "$CURLPATH" != '' ] ; then
	if [ "$(which curl)" = "" ]; then
		echo >&2 "ERR: curl command not found"
		exit 1
	fi
        if [ "$HEADER" != '' ] ; then
          curl -f -H "$HEADER" "$CURLPATH" > /dev/null 2>&1
        else
          curl -f "$CURLPATH" > /dev/null 2>&1
        fi

        result2=$?
        if [ $result2 -eq 0 ] ; then
          exit 0
        fi
      else
        exit 0
      fi
    fi
    sleep 1
  done
  echo "Operation timed out" >&2
  exit 1
}

while [ $# -gt 0 ]
do
  case "$1" in
    *:* )
    HOST=$(printf "%s\n" "$1"| cut -d : -f 1)
    PORT=$(printf "%s\n" "$1"| cut -d : -f 2)
    shift 1
    ;;
    -q | --quiet)
    QUIET=1
    shift 1
    ;;
    -u)
    CURLPATH="$2"
    shift 2
    ;;
    -h)
    HEADER="$2"
    shift 2
    ;;
    -t)
    TIMEOUT="$2"
    if [ "$TIMEOUT" = "" ]; then break; fi
    shift 2
    ;;
    --timeout=*)
    TIMEOUT="${1#*=}"
    shift 1
    ;;
    --)
    shift
    break
    ;;
    --help)
    usage 0
    ;;
    *)
    echoerr "Unknown argument: $1"
    usage 1
    ;;
  esac
done

if [ "$HOST" = "" -o "$PORT" = "" ]; then
  echoerr "Error: you need to provide a host and port to test."
  usage 2
fi

wait_for "$@"
