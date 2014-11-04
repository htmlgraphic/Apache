curl -X POST "https://api.digitalocean.com/v2/droplets" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer f7caadcd3e3c2cb9f501479aa287ec9061bb33b1eb654d77f077a3e698781974" \
-d'{"name":"coreos-7","region":"nyc3","size":"1GB","private_networking":true,"image":"coreos-alpha", "user_data": "'"$(cat cloud-config.yaml | sed 's/"/\\"/g')"'", "ssh_keys":[98825]}'