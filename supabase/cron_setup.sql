-- ============================================================
-- 獲利王 每日自動更新排程設定
-- 每天台灣時間 上午 10:00（UTC 02:00）自動呼叫 Edge Function
-- ============================================================

-- Step 1: 啟用必要的 Extensions（若已啟用可忽略錯誤）
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Step 2: 建立每日排程（若已存在則先刪除舊的）
select cron.unschedule('daily-profit-data-update');

-- Step 3: 新增每日排程
-- cron 格式: 分 時 日 月 星期
-- '0 2 * * *' = 每天 UTC 02:00（台灣時間 10:00）
select cron.schedule(
  'daily-profit-data-update',
  '0 2 * * *',
  $$
  select net.http_post(
    url:='https://yfetqtvzfcoftggdezjz.supabase.co/functions/v1/fetch-profit-data',
    headers:='{"Content-Type": "application/json", "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZXRxdHZ6ZmNvZnRnZ2Rlemp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzI0ODEsImV4cCI6MjA4ODcwODQ4MX0.gk2k1Ibfdf__aFpdPtzd6B79K3GIrK2g-uNopXr4_kk"}'::jsonb,
    body:='{}'::jsonb
  ) as request_id;
  $$
);

-- Step 4: 確認排程已建立
select jobname, schedule, command from cron.job;
