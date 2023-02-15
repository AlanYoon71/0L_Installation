#!/bin/bash
echo ""
echo "==============================";
echo ""
echo "Created by  //-\ ][_ //-\ ][\[";
echo ""
echo "==============================";
echo "                    2023-02-17"
echo ""
echo "This script was created and checked only on 20.04 ubuntu environment."
echo ""
echo ""
cd
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo apt-get install -y prometheus prometheus-node-exporter prometheus-pushgateway prometheus-alertmanager
ps -ef | grep prometheus
sleep 1
#sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main" | grep "NO_PUBKEY" | cut -d ":" -f2
curl -s https://packagecloud.io/install/repositories/grafana/stable/script.deb.sh | sudo bash
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
curl https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get install grafana
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
ps -ef | grep grafana
sudo tee -a /etc/prometheus/prometheus.yml > /dev/null <<EOF
  - job_name: metrics
    static_configs:
      - targets: ['localhost:9101', 'localhost:9102']
EOF
sleep 0.5
sudo systemctl reload prometheus.service

echo "Done!!"


