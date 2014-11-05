curl -X POST "https://api.digitalocean.com/v2/droplets" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $DO_TOKEN" \
-d'{"name":"coreos-19","region":"nyc3","size":"1GB","private_networking":true,"image":"coreos-alpha", "user_data": "'"$(cat cloud-config.yaml | sed 's/"/\\"/g')"'", "ssh_keys":[98825]}'