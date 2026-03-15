import os
import json
from playwright.sync_api import sync_playwright
# pip install playwright supabase
from supabase import create_client, Client

# 從環境變數中取得 Supabase 連線資訊 (GitHub Secrets自動帶入)
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
supabase: Client = create_client(url, key)

etf_list = ['0050', '0056', '00878', '00919', '00929', '006208', '00713', '00881', '00915', '00918']

def scrape_etf(p, etf_code):
    print(f"--- 開始抓取 {etf_code} 成分股 ---")
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    
    # 這裡我們使用 玩股網 或 嗨投資 做為資料源
    # 台灣主要 ETF 資料在 嗨投資 或 玩股網 都有完整張數與權重
    try:
        url = f"https://www.wantgoo.com/etf/{etf_code}/constituent"
        page.goto(url, timeout=60000)
        page.wait_for_selector("table", timeout=10000)
        
        # 讀取表格行
        rows = page.query_selector_all("table tbody tr")
        data_rows = []
        
        for row in rows:
            cells = row.query_selector_all("td")
            if len(cells) < 4:
                continue
            
            # 依據 Wantgoo 表格結構解析
            # 欄位大約為: 股票名稱(代碼), 權重, 張數/持股, 等等
            name_and_symbol = cells[0].inner_text().strip()
            weight_text = cells[1].inner_text().strip().replace('%', '') # 權重百分比
            shares_text = cells[2].inner_text().strip().replace(',', '') # 主要張數
            
            # 拆分名稱與代號，通常格式為 "台積電(2330)"
            if '(' in name_and_symbol and ')' in name_and_symbol:
                symbol = name_and_symbol.split('(')[1].replace(')', '').strip()
            else:
                continue # 如果沒抓到代號則跳過
                
            try:
                weight = float(weight_text)
                shares = int(float(shares_text)) # 可能有小數點，轉 float 再轉 int
            except:
                continue
                
            data_rows.append({
                "etf_symbol": etf_code,
                "stock_symbol": symbol,
                "shares": shares,
                "weight": weight
            })
            
        browser.close()
        return data_rows
    except Exception as e:
        print(f"抓取 {etf_code} 異常: {e}")
        browser.close()
        return []

def main():
    if not url or not key:
        print("缺少 Supabase 憑證設定")
        return

    all_data = []
    with sync_playwright() as p:
        for etf in etf_list:
            items = scrape_etf(p, etf)
            all_data.extend(items)
            
    if all_data:
        print(f"準備寫入 {len(all_data)} 筆資料至 Supabase...")
        try:
            # 使用 Upsert (如果有衝突就覆蓋 stock_symbol, etf_symbol 組合)
            # 在寫入大數據前，可先執行：supabase.table("etf_holdings").delete().execute() 清除舊資料，保持最新
            supabase.table("etf_holdings").delete().neq('etf_symbol', 'INVALID_SYMBOL_NEVER_MATCH').execute() 
            
            res = supabase.table("etf_holdings").insert(all_data).execute()
            print("資料自動同步完成！")
        except Exception as e:
             print(f"寫入 Supabase 失敗: {e}")
    else:
        print("本次未抓取到任何資料。")

if __name__ == "__main__":
    main()
