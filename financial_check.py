import urllib.request, json, os

endpoints = {
  "t187ap17": "https://openapi.twse.com.tw/v1/opendata/t187ap17_L",
  "t187ap06_ci": "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_ci",
  "t187ap06_basi": "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_basi",
  "t187ap06_fh": "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_fh"
}

headers = {'User-Agent': 'Mozilla/5.0'}

def get_data(url):
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode('utf-8'))
    except Exception as e:
        return []

output_lines = []

test_symbols = ['2881', '2882', '2891', '2886'] # 富邦, 國泰, 中信, 兆豐

for name, url in endpoints.items():
    data = get_data(url)
    output_lines.append(f"--- [{name}] loaded {len(data)} items ---")
    for item in data:
        symbol = item.get('公司代號', item.get('Code', '')).strip()
        if symbol in test_symbols:
            output_lines.append(f"\n[{name}] Symbol: {symbol} ({item.get('公司名稱','')})")
            for k,v in item.items():
                if any(kw in k for kw in ['收益','淨利','淨損','歸屬','母公司', '綜合']):
                    if v and str(v).strip() not in ['', '0', '0.00']:
                        output_lines.append(f"  [{k}] = {v}")

with open('financial_check.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output_lines))
