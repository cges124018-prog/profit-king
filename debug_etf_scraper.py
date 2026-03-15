from playwright.sync_api import sync_playwright

def scrape_etf(p, etf_code):
    print(f"--- 測試抓取 {etf_code} 成分股 ---")
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    
    try:
        url = f"https://www.wantgoo.com/etf/{etf_code}/constituent"
        page.goto(url, timeout=60000)
        page.wait_for_selector("table", timeout=10000)
        
        # 讀取所有表格
        tables = page.query_selector_all("table")
        print(f"找到 {len(tables)} 個表格。")
        
        for t_idx, table in enumerate(tables):
             rows = table.query_selector_all("tbody tr")
             print(f"表格 {t_idx} 包含 {len(rows)} 行。")
             for r_idx, row in enumerate(rows[:5]): # 打印前 5 行
                  cells = row.query_selector_all("td")
                  print(f"  行 {r_idx} 有 {len(cells)} 列:")
                  for c_idx, cell in enumerate(cells):
                       print(f"    列 {c_idx}: {cell.inner_text()}")
             print("\n")
             
        browser.close()
    except Exception as e:
        print(f"抓取 {etf_code} 異常: {e}")
        browser.close()

with sync_playwright() as p:
    scrape_etf(p, "0050")
