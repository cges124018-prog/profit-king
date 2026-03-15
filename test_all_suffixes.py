import urllib.request, json

suffixes = ["ci", "basi", "fh", "ins", "se", "other", "leasing", "otherfin"]
base_url = "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_"

headers = {'User-Agent': 'Mozilla/5.0'}

output_lines = []

for suf in suffixes:
    url = base_url + suf
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            data = json.loads(r.read().decode('utf-8'))
            output_lines.append(f"--- [_L_{suf}] loaded {len(data)} items ---")
            symbols = []
            for item in data:
                 symbol = item.get('公司代號', item.get('Code', '')).strip()
                 name_str = item.get('公司名稱', '')
                 symbols.append(f"{symbol} ({name_str})")
            output_lines.append(", ".join(symbols))
    except Exception as e:
        output_lines.append(f"--- [_L_{suf}] Error: {e} ---")

with open('financial_test_all.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output_lines))
