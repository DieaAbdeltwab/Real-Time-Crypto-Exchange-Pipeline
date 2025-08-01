FROM apache/airflow:2.9.1-python3.10

# Switch to root just to install system packages (Java)
USER root

# Install Java and curl
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk-headless \
    curl \
    && apt-get clean

# Set Java env vars
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Copy requirements
COPY requirements.txt /requirements.txt

# ✅ Switch back to airflow user BEFORE installing Python packages
USER airflow

# ✅ Use the pre-configured virtualenv
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r /requirements.txt

