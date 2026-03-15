import urllib.request, json, os

url_ci = 'https://openapi.twse.com.tw/v1/opendata/t187ap06_L_ci'
url_17 = 'https://openapi.twse.com.tw/v1/opendata/t187ap17_L'

headers = {'User-Agent': 'Mozilla/5.0'}

def get_data(url):
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read().decode('utf-8'))
    except Exception as e:
        return []

data_17 = get_data(url_17)
data_ci = get_data(url_ci)

output_lines = [
    f"data_17 size: {len(data_17)}",
    f"data_ci size: {len(data_ci)}"
]

test_symbols = ['1215', '1216', '2330', '3017']

def process_item(item, source):
    symbol = item.get('公司代號', item.get('Code', '')).strip()
    if symbol not in test_symbols:
        return None
        
    profitCandidatesNames = [
        "綜合損益總額歸屬於母公司業主", # Add just to see value
        "淨利（淨損）歸屬於母公司業主",
        "淨利（損）歸屬於母公司業主",
        "稅後淨利(千元)",
        "歸屬於母公司業主之淨利（損）",
        "本期淨利（淨損）",
        "稅前淨利（淨損）",
        "本期稅後淨利（淨損）",
        "繼續營業單位稅後淨利（淨損）",
    ]
    
    candidates = []
    found_values = {}
    for k in profitCandidatesNames:
        v = item.get(k, 0)
        found_values[k] = v
        if not v:
            candidates.append(0.0)
        else:
            try:
                n = float(str(v).replace(',', ''))
                candidates.append(n)
            except:
                candidates.append(0.0)
                
    # Max excluding index 0 (which is "綜合損益_") since index.ts doesn't have it
    candidates_actual = candidates[1:] 
    max_val = max(candidates_actual) if candidates_actual else 0
    
    output_lines.append(f"\n--- [{source}] Symbol: {symbol} ---")
    output_lines.append(f"  All available fields: ")
    for k, v in item.items():
        if any(kw in k for kw in ['收益','淨利','淨損','歸屬','母公司', '綜合']):
            if v and str(v).strip() not in ['', '0', '0.00']:
                output_lines.append(f"    [{k}] = {v}")
    output_lines.append(f"  Candidates processing:")
    for name, val in zip(profitCandidatesNames[1:], candidates_actual):
         if val != 0:
             output_lines.append(f"    {name}: {val}")
    output_lines.append(f"  Chosen (Math.max): {max_val}")
    output_lines.append(f"  netIncome (max * 1000): {max_val * 1000}")


for item in data_17:
    process_item(item, "t187ap17")

for item in data_ci:
    process_item(item, "t187ap06")

with open('simulate_output.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(output_lines))
