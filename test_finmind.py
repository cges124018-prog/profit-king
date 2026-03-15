import urllib.request, json

url = "https://api.finmindtrade.com/api/v4/data?dataset=TaiwanStockETF&data_id=0050"

try:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read().decode('utf-8'))
        print(f"Status: {data.get('status')}")
        if 'data' in data and data['data']:
             print(f"Loaded {len(data['data'])} rows!")
             print(data['data'][:3]) # Print first 3 rows
        else:
             print("No data in 'data' field.")
except Exception as e:
    print(f"Error: {e}")
