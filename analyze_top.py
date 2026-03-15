
import json
import urllib.request

url = "https://openapi.twse.com.tw/v1/opendata/t187ap17_L"
headers = {"User-Agent": "Mozilla/5.0"}
req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req) as response:
        content = response.read().decode('utf-8')
        data = json.loads(content)
        print(f"Total items: {len(data)}")
        
        # Filter out empty entries
        real_data = [item for item in data if item.get("公司代號")]
        print(f"Real items: {len(real_data)}")
        
        # Sort by profit
        # Field name: 稅後淨利(千元)
        sorted_data = sorted(real_data, key=lambda x: float(x.get("稅後淨利(千元)", 0).replace(",", "") if x.get("稅後淨利(千元)") else 0), reverse=True)
        
        print("\nTop 15 by Profit in t187ap17_L:")
        for i, item in enumerate(sorted_data[:15]):
            print(f"{i+1}. {item.get('公司名稱')} ({item.get('公司代號')}) - {item.get('稅後淨利(千元)')}")
            
        fubon = [item for item in real_data if item.get("公司代號") == "2881"]
        if fubon:
            print(f"\nFOUND Fubon: {fubon[0]}")
except Exception as e:
    print(f"Error: {e}")
