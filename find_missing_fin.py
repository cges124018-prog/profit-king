import urllib.request, json

endpoints = {
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

keywords = ['富邦', '國泰', '玉山', '兆豐', '金控', '銀行']

for name, url in endpoints.items():
    data = get_data(url)
    output_lines.append(f"\n--- [{name}] items count: {len(data)} ---")
    for item in data:
         name_str = item.get('公司名稱', '')
         symbol = item.get('公司代號', item.get('Code', '')).strip()
         if any(kw in name_str for kw in keywords) or symbol.startswith('28'):
             output_lines.append(f"  {symbol}: {name_str}")

with open('find_missing_fin.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output_lines))
