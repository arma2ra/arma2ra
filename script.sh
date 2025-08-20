#!/bin/bash
# set token
TOKEN="$1"

# get dump and decode
curl "https://hackattic.com/challenges/backup_restore/problem?access_token=$TOKEN" \
  | jq -r '.dump' \
  | base64 -d > pg_dump.decoded

# unzip dump
gzip -dc pg_dump.decoded > pg_dump.sql

# run docker container with postgres
sudo docker run -d --name pg_test \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=pg_test \
  -p 5432:5432 \
  postgres:15

# wait until postgres ready
until sudo docker exec pg_test pg_isready -U postgres > /dev/null 2>&1; do
  sleep 1
done

# restore dump
cat pg_dump.sql | sudo docker exec -i pg_test psql -U postgres -d pg_test

# get alive_ssns (tuples only, unaligned)
sudo docker exec pg_test psql -U postgres -d pg_test -t -A -c "SELECT ssn FROM criminal_records WHERE status='alive';" > alive_ssns.txt

# show result
clear
echo Results:
cat alive_ssns.txt
echo ---

# delete container
sudo docker container rm -f pg_test
