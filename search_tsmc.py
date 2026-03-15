
import requests
import json

endpoints = [
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_X_ci",
    "https://openapi.twse.com.tw/v1/opendata/t187ap05_L",
    "https://openapi.twse.com.tw/v1/opendata/t187ap11_L",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_X_ci"
]

headers = {"User-Agent": "Mozilla/5.0"}

for url in endpoints:
    print(f"Checking {url}...")
    try:
        r = requests.get(url, headers=headers, timeout=10)
        if "2330" in r.text:
            print(f"FOUND 2330 in {url}!")
            # Sample data
            data = r.json()
            for item in data:
                if item.get("公司代號") == "2330" or item.get("Code") == "2330":
                    print(json.dumps(item, indent=2, ensure_ascii=False))
                    break
        else:
            print(f"Not found in {url}")
    except Exception as e:
        print(f"Error: {e}")
