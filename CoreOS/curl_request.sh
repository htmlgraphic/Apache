curl -X POST "https://api.digitalocean.com/v2/droplets" \
-H "Content-Type: application/json" \
-H "Authorization: Bearer f7caadcd3e3c2cb9f501479aa287ec9061bb33b1eb654d77f077a3e698781974" \
-d'{"name":"coreos-3","region":"nyc3","size":"512mb","private_networking":true,"image":"coreos-stable", "user_data": "'"$(cat cloud-config.yaml | sed 's/"/\\"/g')"'", "ssh_keys":[98825]}'
