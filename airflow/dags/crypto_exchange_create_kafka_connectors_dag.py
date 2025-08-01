from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

default_args = {
    "start_date": datetime(2023, 1, 1),
    "catchup": False
}

with DAG(
    dag_id="crypto_exchange_create_kafka_connectors",
    default_args=default_args,
    schedule_interval=None,
    description="Creates Kafka Connectors for crypto and fiat prices",
) as dag:

    create_crypto_connector = BashOperator(
        task_id="create_crypto_connector",
        bash_command="""
        curl -X PUT http://connect:8083/connectors/coingecko-http-source/config \
        -H "Content-Type: application/json" \
        -d '{
          "connector.class": "com.github.castorm.kafka.connect.http.HttpSourceConnector",
          "tasks.max": "1",
          "kafka.topic": "crypto_prices",
          "http.request.url": "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,solana,ripple,dogecoin,cardano,polkadot,the-open-network,litecoin,shiba-inu,avalanche-2,chainlink,uniswap,stellar&vs_currencies=usd,eur,egp,sar,aed",
          "http.request.method": "GET",
          "poll.interval.ms": "10000",
          "value.converter": "org.apache.kafka.connect.json.JsonConverter",
          "value.converter.schemas.enable": "false"
        }'
        """
    )

    create_fiat_connector = BashOperator(
        task_id="create_fiat_connector",
        bash_command="""
        curl -X PUT http://connect:8083/connectors/fiat-exchange-rates/config \
        -H "Content-Type: application/json" \
        -d '{
          "connector.class": "com.github.castorm.kafka.connect.http.HttpSourceConnector",
          "tasks.max": "1",
          "kafka.topic": "fiat_exchange_rates",
          "http.request.url": "https://api.coingecko.com/api/v3/simple/price?ids=usd,eur,egp,sar,aed,kwd,qar,bhd,jod,try,gbp&vs_currencies=usd,eur,egp,sar,aed,kwd,qar,bhd,jod,try,gbp",
          "http.request.method": "GET",
          "poll.interval.ms": "10000",
          "value.converter": "org.apache.kafka.connect.json.JsonConverter",
          "value.converter.schemas.enable": "false"
        }'
        """
    )

    create_crypto_connector >> create_fiat_connector

