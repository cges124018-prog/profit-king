import urllib.request, urllib.parse, json

url = "https://mops.twse.com.tw/mops/web/ajax_t78sb07" # ETF Constituents
# POST Form Data
params = {
    'encode_data': '1',
    'step': '1',
    'firstin': 'true',
    'co_id': '0050',
    'TYPEK': 'all'
}

data = urllib.parse.urlencode(params).encode('utf-8')
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...'
}

try:
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req) as r:
        html = r.read().decode('utf-8')
        print(f"MOPS HTML Length: {len(html)}")
        if "台積電" in html:
            print("Found 台積電 inside MOPS!")
        else:
            print("Not found inside MOPS.")
except Exception as e:
    print(f"Error: {e}")
