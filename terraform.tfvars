# terraform.tfvars

pm_api_url           = "https://192.168.1.71:8006/api2/json"
pm_api_token_id      = "terraform@pam!terraform"
pm_api_token_secret  = "81fff33d-1194-40f6-a09b-5e4ffee88809"
pm_tls_insecure      = true


db_server_ip       = "192.168.1.130" # The actual IP
db_server_netmask  = 24              # The subnet mask
db_server_gateway  = "192.168.1.1"   # The gateway

app_server_ip      = "192.168.1.140"
app_server_netmask = 24
app_server_gateway = "192.168.1.1"

