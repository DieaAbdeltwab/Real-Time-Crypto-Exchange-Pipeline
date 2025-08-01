-- Active: 1751788548434@@127.0.0.1@8123@default

CREATE DATABASE IF NOT EXISTS crypto_exchange;

USE crypto_exchange;
-- ===================================================
-- ===================================================

CREATE TABLE crypto_exchange.converted_prices (
  currency String,
  vs_currency String,
  price Float64,
  to_currency String,
  fx_rate Float64,
  converted_price Float64,
  inserted_at DateTime
) ENGINE = MergeTree()
ORDER BY (currency, inserted_at);


