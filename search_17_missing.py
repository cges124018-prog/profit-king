import urllib.request, json

url = "https://openapi.twse.com.tw/v1/opendata/t187ap17_L"
headers = {'User-Agent': 'Mozilla/5.0'}

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read().decode('utf-8'))
        print(f"Total: {len(data)} items")
        found = []
        for item in data:
            name_str = item.get('公司名稱', '')
            symbol = item.get('公司代號', item.get('Code', '')).strip()
            if '2881' in symbol or '富邦' in name_str or '國泰' in name_str or '2882' in symbol:
                found.append(f"{symbol}: {name_str}")
        print("\n".join(found))
except Exception as e:
    print(f"Error: {e}")
