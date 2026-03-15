import cloudscraper

scraper = cloudscraper.create_scraper() # returns a CloudScraper instance

url = "https://www.wantgoo.com/etf/0050/constituent"

try:
    response = scraper.get(url)
    print(f"Status Code: {response.status_code}")
    print(f"HTML Length: {len(response.text)}")
    with open("wantgoo_0050_con.html", "w", encoding="utf-8") as f:
        f.write(response.text[:50000]) # save first 50KB to inspect table
except Exception as e:
    print(f"Error: {e}")
