curl -X POST "https://api.digitalocean.com/v2/droplets" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $DO_TOKEN" \
-d'{"name":"coreos61","region":"nyc3","size":"512mb","private_networking":true,"image":"coreos-stable", "user_data": "'"$(cat cloud-config.yaml | sed 's/"/\\"/g')"'", "ssh_keys":[98825]}'