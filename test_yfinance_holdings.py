import yfinance as yf

# 使用 yfinance 測試 0050.TW 
try:
    ticker = yf.Ticker("0050.TW")
    print("--- 0050.TW Info ---")
    info = ticker.info
    print(f"Name: {info.get('longName')}")
    print(f"Sector: {info.get('sector')}")
    print(f"Holdings: {ticker.holdings}") # yfinance returns top 10 ETF holdings occasionally
except Exception as e:
    print(f"Error: {e}")
