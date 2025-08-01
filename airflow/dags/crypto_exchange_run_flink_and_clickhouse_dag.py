from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime
from clickhouse_connect import get_client

default_args = {
    "start_date": datetime(2023, 1, 1),
    "catchup": False
}

dag = DAG(
    dag_id="crypto_exchange_create_clickhouse_and_run_flink",
    default_args=default_args,
    schedule_interval=None,
    description="Create ClickHouse table and run Flink SQL job",
)

# Task 1: Create ClickHouse Table
def create_clickhouse_table():
    client = get_client(host='clickhouse', username='default', password='123')

    # أولاً: إنشاء قاعدة البيانات
    client.command("CREATE DATABASE IF NOT EXISTS crypto_exchange")

    # ثانياً: إنشاء الجدول داخل قاعدة البيانات
    client.command("""
        CREATE TABLE IF NOT EXISTS crypto_exchange.converted_prices (
            currency String,
            vs_currency String,
            price Float64,
            to_currency String,
            fx_rate Float64,
            converted_price Float64,
            inserted_at DateTime 
        ) ENGINE = MergeTree()
        ORDER BY currency
    """)


create_table_task = PythonOperator(
    task_id="create_clickhouse_table",
    python_callable=create_clickhouse_table,
    dag=dag,
)

# Task 2: Run Flink SQL Job
run_flink_job = BashOperator(
    task_id="run_flink_job",
    bash_command="""
    docker exec flink-jobmanager \
    ./bin/sql-client.sh embedded -f /opt/flink/scripts/flink_crypto_exchange.sql
    """,
    dag=dag,
)

# Set task dependencies
create_table_task >> run_flink_job

