

# 269
curl 'https://api.pugetsound.onebusaway.org/api/where/trips-for-route/1_100160.json?key=OBAKEY' > tmp/oba.snapshot.json
curl 'https://api.pugetsound.onebusaway.org/api/where/trips-for-route/1_100160.json?key=TEST'
curl 'https://api.pugetsound.onebusaway.org/api/where/trips-for-route/1_100160.json?key='(rsec OneBusAway_KEY)

cat oba.snapshot.json | json2table data/references/trips
cat oba.snapshot.json | json2table data/list/status

cat oba.snapshot.json | json2table data/references/trips/id,tripHeadsign
cat oba.snapshot.json | json2table data/list/status/distanceAlongTrip,activeTripId,nextStop,lastLocationUpdateTime

## real script download:
# Create status table
cat oba.snapshot.json | json2table data/list/status/distanceAlongTrip,activeTripId,nextStop,lastLocationUpdateTime -p | grep -v '|0|0|' > status.tbl

# Create trips table
cat oba.snapshot.json | json2table data/references/trips/id,tripHeadsign -p > trips.tbl

# Join files on first field (trip id, field separator is '|')
join -t'|' -1 1 -2 1 <(sort -t'|' -k1,1 status.tbl) <(sort -t'|' -k1,1 trips.tbl) > joined.tbl

cat joined.tbl

