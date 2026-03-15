
import requests
import json

headers = {"User-Agent": "Mozilla/5.0"}
r = requests.get("https://openapi.twse.com.tw/v1/swagger.json", headers=headers)
swagger = r.json()

target_paths = ["/opendata/t187ap14_L", "/opendata/t187ap15_L", "/opendata/t187ap16_L", "/opendata/t187ap11_L"]
for path in target_paths:
    if path in swagger["paths"]:
        print(f"{path}: {swagger['paths'][path]['get']['summary']}")
