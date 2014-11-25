# Create a new node on Digital Ocean
# By Jason Gegere <jason@htmlgraphic.com>

curl -X POST "https://api.digitalocean.com/v2/droplets" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $DO_TOKEN" \
-d'{"name":"coreos62","backups":true,"region":"nyc3","size":"1gb","private_networking":true,"image":"coreos-stable", "user_data": "'"$(cat cloud-config.yaml | sed 's/"/\\"/g')"'", "ssh_keys":[98825]}'