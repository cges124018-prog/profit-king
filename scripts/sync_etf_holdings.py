import requests
from bs4 import BeautifulSoup
import re
import warnings
from supabase import create_client, Client

# 忽略 SSL 未驗證警告 (僅開發本地測試使用，若正常連線可刪除)
warnings.filterwarnings('ignore', message='Unverified HTTPS request')

# 🟢 Supabase 憑證設定 (自動帶入您 main.dart 內的設定)
SUPABASE_URL = "https://yfetqtvzfcoftggdezjz.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZXRxdHZ6ZmNvZnRnZ2Rlemp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzI0ODEsImV4cCI6MjA4ODcwODQ4MX0.gk2k1Ibfdf__aFpdPtzd6B79K3GIrK2g-uNopXr4_kk"

# 初始化 Supabase
try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
except Exception as e:
    print(f"Supabase 連線失敗: {e}")
    exit(1)

def get_etf_list():
    """從 supabase 取得當前有追蹤的 ETF 清單"""
    try:
        response = supabase.table("etfs").select("symbol, name").execute()
        return response.data
    except Exception as e:
        print(f"取得 ETF 清單失敗: {e}")
        return []

def scrape_etf_holdings(etf_symbol):
    """跟據 ETF 代碼，連網爬取所有持股明細"""
    holdings = []
    # 💡 使用 Basic0007B.xdjhtm 可以爬取到「完整」成分股，不限於前十大
    url = f"https://www.moneydj.com/ETF/X/Basic/Basic0007B.xdjhtm?etfid={etf_symbol}.TW"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    try:
        # verify=False 繞過某些本機 SSL 握手時的報錯
        response = requests.get(url, headers=headers, verify=False, timeout=10)
        if response.status_code != 200:
            print(f"[{etf_symbol}] 網頁連線異常: {response.status_code}")
            return holdings

        soup = BeautifulSoup(response.content, 'html.parser')
        # 尋找持股明細的表格
        table = soup.find('table', id='ctl00_ctl00_MainContent_MainContent_stable3')
        if not table:
            print(f"[{etf_symbol}] 找不到持股明細表格表格 id (可能結構不同)")
            return holdings

        tbody = table.find('tbody')
        if not tbody:
            print(f"[{etf_symbol}] 找不到 tbody")
            return holdings

        rows = tbody.find_all('tr')
        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 3:
                # 1. 抓取名稱與代碼 (例：台積電(2330.TW))
                name_text = cells[0].get_text(strip=True)
                match = re.search(r'\((\d{4})\.', name_text) # 提取刮號內的數字 2330
                if not match:
                     continue # 不是標準台股 4 碼則跳過
                stock_symbol = match.group(1)

                # 2. 爬取持股比例 (%)
                weight_text = cells[1].get_text(strip=True)
                weight = float(weight_text) if weight_text else 0.0

                # 3. 爬取持股股數
                shares_text = cells[2].get_text(strip=True).replace(',', '')
                shares = int(float(shares_text)) if shares_text else 0 # 轉型為 int

                holdings.append({
                    "etf_symbol": etf_symbol,
                    "stock_symbol": stock_symbol,
                    "weight": weight,
                    "shares": shares,
                    "data_date": "2026/03/19" # 可以帶入當日的時間日期
                })

    except Exception as e:
        print(f"處理 [{etf_symbol}] 發生錯誤: {e}")

    return holdings

def main():
    print("🚀 啟動 ETF 持股自動同步更新程序...")
    etfs = get_etf_list()
    if not etfs:
        print("❌ Supabase 中沒有設定任何 ETF 計算清單。")
        return

    print(f"📊 即將更新 {len(etfs)} 檔 ETF 的持有股票權重資訊...")
    all_inserted = 0

    for etf in etfs:
        symbol = etf['symbol']
        name = etf['name']
        print(f" -> 正在抓取 [{symbol}] {name} ... ", end="")
        
        holdings = scrape_etf_holdings(symbol)
        if holdings:
            try:
                # 使用 upsert 根據 etf_holdings 規則覆蓋 
                # (設定 on_conflict 指定唯一鍵，以防 duplicate key 報錯)
                res = supabase.table("etf_holdings").upsert(
                    holdings, 
                    on_conflict="etf_symbol,stock_symbol"
                ).execute()
                print(f"成功同步 {len(holdings)} 檔成分股")
                all_inserted += len(holdings)
            except Exception as e:
                 print(f"寫入 Supabase 失敗: {e}")
        else:
             print("無資料檔")

    print(f"✅ 完成！共寫入/更新了 {all_inserted} 筆持股紀錄到 etf_holdings 表格。")

if __name__ == "__main__":
    main()
