
import json
import urllib.request

url = "https://openapi.twse.com.tw/v1/opendata/t187ap11_L"
headers = {"User-Agent": "Mozilla/5.0"}
req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
        print(f"Total items: {len(data)}")
        found = [item for item in data if item.get("公司代號") == "2881"]
        if found:
            print("Found 2881:")
            print(json.dumps(found[0], indent=2, ensure_ascii=False))
        else:
            print("2881 not found.")
            # Print sample to see field names
            if data:
                print("First item keys:", data[0].keys())
except Exception as e:
    print(f"Error: {e}")
