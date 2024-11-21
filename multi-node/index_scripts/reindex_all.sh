#!/bin/bash

# if [ "$1" == "" ] || [ "$2" == "" ]; then
#   echo "Usage: ./reindex.sh [REMOTE_HOST:REMOTE_PORT] [INDEX_PATTERN] [LOCAL_HOST:LOCAL_PORT]"
#   exit 1
# fi
set -e
MAPPINGS=$(cat ./mappings.json | jq -r . | tr -d "[:space:]" | sed 's:":\\":g')
function createIndexTmpl {
  echo '{
    "settings": {
      "number_of_shards": 1
    },
    "mappings": "${MAPPINGS}"
  }'
}

REMOTE_HOST=https://0.0.0.0:9200
PATTERN=wazuh-alerts-*
LOCAL_HOST=$REMOTE_HOST
CURL_PRE="-k -u admin:SecretPassword -H 'Content-Type: application/json'"

INDICES=$(curl ${CURL_PRE} --silent "$REMOTE_HOST/_cat/indices/$PATTERN?h=index")
TOTAL_INCOMPLETE_INDICES=0
TOTAL_INDICES=0
TOTAL_DURATION=0
INCOMPLETE_INDICES=()


set -x
for INDEX in $INDICES; do
  if [[ ${INDEX} = *_updated ]]; then
    continue
  fi
  TOTAL_DOCS_REMOTE=$(curl --silent ${CURL_PRE} "${REMOTE_HOST}/_cat/indices/${INDEX}?h=docs.count")
  echo "Attempting to re-indexing $INDEX ($TOTAL_DOCS_REMOTE docs total)"
  exit 0
  SECONDS=0
  curl -XPUT ${CURL_PRE} ${REMOTE_HOST}/${INDEX}_updated -d '$(createIndexTmpl)'
  echo "Put Index: $?"
  curl -XPOST ${CURL_PRE} "${REMOTE_HOST}/_reindex?wait_for_completion=true&pretty=true" -d "{
    \"conflicts\": \"proceed\",
    \"source\": {
      \"index\": \"${INDEX}\"
    },
    \"dest\": {
      \"index\": \"${INDEX}_updated\"
    }
  }"
  echo "Re Index: $?"
  duration=$SECONDS

  LOCAL_INDEX_EXISTS=$(curl ${CURL_PRE} -o /dev/null --silent --head --write-out '%{http_code}' "${REMOTE_HOST}/${INDEX}_updated")
  if [ "$LOCAL_INDEX_EXISTS" == "200" ]; then
    TOTAL_DOCS_REINDEXED=$(curl --silent ${CURL_PRE} "http://$LOCAL_HOST/_cat/indices/${INDEX}_updated?h=docs.count")
  else
    TOTAL_DOCS_REINDEXED=0
  fi

  echo "    Re-indexing results:"
  echo "     -> Time taken: $(($duration / 60)) minutes and $(($duration % 60)) seconds"
  echo "     -> Docs indexed: $TOTAL_DOCS_REINDEXED out of $TOTAL_DOCS_REMOTE"
  echo ""

  TOTAL_DURATION=$(($TOTAL_DURATION+$duration))

  if [ "$TOTAL_DOCS_REMOTE" -ne "$TOTAL_DOCS_REINDEXED" ]; then
    TOTAL_INCOMPLETE_INDICES=$(($TOTAL_INCOMPLETE_INDICES+1))
    INCOMPLETE_INDICES+=($INDEX)
  fi
  curl -XDELETE ${CURL_PRE} "$REMOTE_HOST/$INDEX"
  echo "Delete ${INDEX} $?"

  TOTAL_INDICES=$((TOTAL_INDICES+1))
  break
done

echo "---------------------- STATS --------------------------"
echo "Total Duration of Re-Indexing Process: $((TOTAL_DURATION / 60))m $((TOTAL_DURATION % 60))"
echo "Total Indices: $TOTAL_INDICES"
echo "Total Incomplete Re-Indexed Indices: $TOTAL_INCOMPLETE_INDICES"
if [ "$TOTAL_INCOMPLETE_INDICES" -ne "0" ]; then
  printf '%s\n' "${INCOMPLETE_INDICES[@]}"
fi
echo "-------------------------------------------------------"
echo ""
