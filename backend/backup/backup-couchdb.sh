#!/bin/bash
# Backup quotidien CouchDB
docker compose exec couchdb curl -X GET http://$COUCHDB_USER:$COUCHDB_PASSWORD@localhost:5984/seedballs/_all_docs?include_docs=true | gzip > ~/seedballplantation/backup/seedballs-$(date +%Y%m%d).json.gz
