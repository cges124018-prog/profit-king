import urllib.request, json

url = "https://openapi.twse.com.tw/v1/opendata/t187ap06_L_fh"
headers = {'User-Agent': 'Mozilla/5.0'}

try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read().decode('utf-8'))
        for item in data:
            if item.get('公司代號', '').strip() == '2891':
                print(f"--- Keys for 2891 ---")
                for k in item.keys():
                    print(f"[{repr(k)}] -> {item[k]}")
except Exception as e:
    print(f"Error: {e}")
