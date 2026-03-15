
import json
import urllib.request

headers = {"User-Agent": "Mozilla/5.0"}
swagger_url = "https://openapi.twse.com.tw/v1/swagger.json"

req = urllib.request.Request(swagger_url, headers=headers)
with urllib.request.urlopen(req) as response:
    swagger = json.loads(response.read().decode('utf-8'))

paths = [p for p in swagger["paths"].keys() if p.startswith("/opendata/t")]

print(f"Checking {len(paths)} paths...")
for path in paths:
    url = f"https://openapi.twse.com.tw/v1{path}"
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=3) as r:
            content = r.read().decode('utf-8', errors='ignore')
            if "2881" in content:
                print(f"FOUND 2881 in {path}")
                # Try to extract the row
                data = json.loads(content)
                for item in data:
                    if str(item.get("公司代號", "")) == "2881" or str(item.get("Code", "")) == "2881":
                        print("Match found!")
                        print(json.dumps(item, indent=2, ensure_ascii=False))
                        break
    except:
        continue
