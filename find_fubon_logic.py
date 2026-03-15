
import json
import urllib.request

def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode('utf-8'))

def find_by_code(data, code):
    if not isinstance(data, list): return None
    for item in data:
        # Check all values for the code string
        if any(str(v).strip() == str(code) for v in item.values()):
            return item
    return None

# Check Basic Info
print("Checking Basic Info (t187ap03_L)...")
basic = fetch_json("https://openapi.twse.com.tw/v1/opendata/t187ap03_L")
fubon = find_by_code(basic, "2881")
if fubon:
    print("Found 2881 in Basic Info!")
    print(json.dumps(fubon, indent=2, ensure_ascii=False))
else:
    print("2881 not found in Basic Info.")

# Check Profit tables
profit_urls = [
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_ci",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_fh",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_basi",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_ins",
    "https://openapi.twse.com.tw/v1/opendata/t187ap06_X_fh"
]

for url in profit_urls:
    print(f"Checking {url}...")
    try:
        data = fetch_json(url)
        item = find_by_code(data, "2881")
        if item:
            print(f"FOUND 2881 IN {url}!")
            print(json.dumps(item, indent=2, ensure_ascii=False))
            # Beak if found in a primary profit table
    except Exception as e:
        print(f"Error checking {url}: {e}")
