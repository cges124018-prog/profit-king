import urllib.request, json

test_urls = [
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_X_fh",
    "https://openapi.twse.com.tw/opendata/t187ap06_X_fh",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_fh"
]

headers = {'User-Agent': 'Mozilla/5.0'}
output = []

for url in test_urls:
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read().decode('utf-8'))
            output.append(f"--- URL: {url} ---")
            output.append(f"Count: {len(data)}")
            symbols = []
            for item in data:
                 item_symbol = item.get('公司代號', item.get('Code', '')).strip()
                 symbols.append(f"{item_symbol} ({item.get('公司名稱','')})")
            output.append(", ".join(symbols))
            output.append("\n")
    except Exception as e:
        output.append(f"--- URL: {url} Failed: {e} ---\n")

with open('test_X_endpoints.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output))
