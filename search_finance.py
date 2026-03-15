
import requests
import json

codes = ["2881", "2882", "2330"]
endpoints = [
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_ci",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_basi",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_fh",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_ins",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_mim",
    "https://openapi.twse.com.tw/v1/opendata/t187ap11_L",
    "https://openapi.twse.com.tw/v1/opendata/t187ap17_L"
]

headers = {"User-Agent": "Mozilla/5.0"}

for url in endpoints:
    print(f"Checking {url}...")
    try:
        r = requests.get(url, headers=headers, timeout=10)
        if r.status_code != 200:
            print(f"  FAILED: Status {r.status_code}")
            continue
        
        text = r.text
        for code in codes:
            if code in text:
                print(f"  FOUND {code} in {url}!")
                try:
                    data = r.json()
                    for item in data:
                        if item.get("公司代號") == code or item.get("公司代號", "").strip('\ufeff') == code:
                            print(f"    KEYS: {list(item.keys())}")
                            print(f"    DATA: {json.dumps(item, indent=2, ensure_ascii=False)}")
                            # Break after finding first matching code in this url
                            break
                except :
                    print("  JSON Parse error but code found in text.")
    except Exception as e:
        print(f"  Error: {e}")
