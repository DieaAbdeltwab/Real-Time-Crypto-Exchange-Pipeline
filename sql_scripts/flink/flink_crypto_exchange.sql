-- إعداد وضع عرض النتائج
SET 'sql-client.execution.result-mode' = 'TABLEAU';

-- 📌 جدول Kafka: بيانات العملات الرقمية
CREATE TABLE crypto_prices_raw (
  `value` STRING
) WITH (
  'connector' = 'kafka',
  'topic' = 'crypto_prices',
  'properties.bootstrap.servers' = 'broker:29092',
  'format' = 'json',
  'scan.startup.mode' = 'latest-offset'
);

-- 📌 جدول Kafka: بيانات أسعار صرف العملات
CREATE TABLE fiat_rates_raw (
  `value` STRING
) WITH (
  'connector' = 'kafka',
  'topic' = 'fiat_exchange_rates',
  'properties.bootstrap.servers' = 'broker:29092',
  'format' = 'json',
  'scan.startup.mode' = 'latest-offset'
);

-- 📌 View: تنظيف جدول العملات الرقمية (بدون egp)
CREATE VIEW crypto_prices_clean AS
SELECT 'bitcoin' AS currency, 'usd' AS vs_currency, JSON_VALUE(`value`, '$.bitcoin.usd') AS price FROM crypto_prices_raw
UNION ALL SELECT 'ethereum', 'usd', JSON_VALUE(`value`, '$.ethereum.usd') FROM crypto_prices_raw
UNION ALL SELECT 'solana', 'usd', JSON_VALUE(`value`, '$.solana.usd') FROM crypto_prices_raw;

-- 📌 View: تنظيف جدول أسعار الصرف (بدون egp)
CREATE VIEW fiat_rates_clean AS
SELECT 'usd' AS vs_currency, 'usd' AS to_currency, JSON_VALUE(`value`, '$.usd.usd') AS fx_rate FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'eur', JSON_VALUE(`value`, '$.usd.eur') FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'sar', JSON_VALUE(`value`, '$.usd.sar') FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'aed', JSON_VALUE(`value`, '$.usd.aed') FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'kwd', JSON_VALUE(`value`, '$.usd.kwd') FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'bhd', JSON_VALUE(`value`, '$.usd.bhd') FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'try', JSON_VALUE(`value`, '$.usd.try') FROM fiat_rates_raw
UNION ALL SELECT 'usd', 'gbp', JSON_VALUE(`value`, '$.usd.gbp') FROM fiat_rates_raw;

-- 📌 جدول ClickHouse Sink
CREATE TABLE clickhouse_converted_prices (
  currency STRING,
  vs_currency STRING,
  price DOUBLE,
  to_currency STRING,
  fx_rate DOUBLE,
  converted_price DOUBLE,
  inserted_at TIMESTAMP
) WITH (
  'connector' = 'clickhouse',
  'url' = 'jdbc:clickhouse://clickhouse:8123',
  'database-name' = 'crypto_exchange',
  'table-name' = 'converted_prices',
  'username' = 'default',
  'password' = '123'
);


-- 📌 حفظ البيانات إلى ClickHouse
INSERT INTO clickhouse_converted_prices
SELECT 
  c.currency,
  c.vs_currency,
  CAST(c.price AS DOUBLE),
  f.to_currency,
  CAST(f.fx_rate AS DOUBLE),
  CAST(c.price AS DOUBLE) * CAST(f.fx_rate AS DOUBLE),
  CURRENT_TIMESTAMP
FROM crypto_prices_clean c
JOIN fiat_rates_clean f
  ON c.vs_currency = f.vs_currency;

