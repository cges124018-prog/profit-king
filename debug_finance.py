
import requests
import json

headers = {"User-Agent": "Mozilla/5.0"}
url = "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_fh"

try:
    r = requests.get(url, headers=headers, timeout=10)
    data = r.json()
    found = False
    for item in data:
        if item.get("公司代號") == "2881" or item.get("Code") == "2881":
            print("Found Fubon (2881)!")
            print(json.dumps(item, indent=2, ensure_ascii=False))
            found = True
            break
    if not found:
        print("Fubon (2881) not found in the list.")
        # Print keys of the first non-empty item
        for item in data:
            if item.get("公司代號"):
                print(f"Keys in found item: {list(item.keys())}")
                break
except Exception as e:
    print(f"Error: {e}")
