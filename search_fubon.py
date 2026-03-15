
import json
import requests

# Set User-Agent as required by TWSE
headers = {"User-Agent": "Mozilla/5.0"}

def search_fubon():
    print("Searching for Fubon (2881) in TWSE endpoints...")
    # Get all opendata endpoints from swagger
    m = requests.get("https://openapi.twse.com.tw/v1/swagger.json", headers=headers).json()
    paths = [p for p in m['paths'].keys() if '/opendata/t187ap' in p]
    
    for p in paths:
        url = f"https://openapi.twse.com.tw/v1{p}"
        try:
            r = requests.get(url, headers=headers, timeout=5)
            if r.status_code == 200:
                text = r.text
                if "2881" in text:
                    print(f"FOUND 2881 in {url}")
                    # Print summary
                    summary = m['paths'][p]['get']['summary']
                    print(f"  Summary: {summary}")
                    break
        except : pass

if __name__ == "__main__":
    search_fubon()
