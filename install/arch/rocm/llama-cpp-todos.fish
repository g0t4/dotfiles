# todo look into placement on CPU/GPUs
./build/bin/llama-server -h
# i.e.:
--cpu-*
--n-gpu-layers
--split-mode # across GPUs!


--log-colors

--seed SEED


# llama-server specific:
--no-webui
# TODO setup secure home instance w/ HTTPS+apikey:
--api-key
--api-key-file
--ssl-key-file
--ssl-cert-file
#
--metrics # prometheus
#
--jinja # default disabled (IIAC these are the same templates that ollama uses)
--chat-template JINJA_TEMPLATE
--chat-template-file JINJA_TEMPLATE_FILE


