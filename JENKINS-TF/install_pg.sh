#!/bin/bash

# Step 1: Create dedicated Linux user for Prometheus
sudo useradd --system --no-create-home --shell /bin/false prometheus

# Step 2: Download Prometheus
PROMETHEUS_VERSION="2.47.1"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Step 3: Extract Prometheus files, move them, and create directories
tar -xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64/
sudo mkdir -p /data /etc/prometheus
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml

# Step 4: Set ownership for directories
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/

# Step 5: Create a systemd unit configuration file for Prometheus
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

# Step 6: Enable and start Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

#Install Grafana

# Step 1: Update package lists
sudo apt-get update

# Step 2: Install necessary packages
sudo apt-get install -y apt-transport-https software-properties-common

# Step 3: Add the GPG Key for Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# Step 4: Add the repository for Grafana stable releases
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Step 5: Update the package list
sudo apt-get update

# Step 6: Install Grafana
sudo apt-get -y install grafana

# Step 7: Enable Grafana to start on boot
sudo systemctl enable grafana-server

# Step 8: Start Grafana
sudo systemctl start grafana-server

#Install Node Exporter

# Step 1: Create dedicated Linux user for Node Exporter
sudo useradd --system --no-create-home --shell /bin/false node_exporter

# Step 2: Download Node Exporter
NODE_EXPORTER_VERSION="1.6.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Step 3: Extract Node Exporter files, move the binary, and clean up
tar -xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*

# Step 4: Create a systemd unit configuration file for Node Exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
EOF

# Step 5: Enable and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

