# Observability Workshop

This workshop will guide you through setting up and using a complete observability stack with Grafana, Prometheus, Loki, and more.

## Prerequisites

- Docker and Docker Compose
- Git
- Basic Linux command line knowledge
- Web browser

## Workshop Structure

1. [Lab 1: Environment Setup](./lab1-environment-setup/README.md)
2. [Lab 2: Basic Monitoring](./lab2-basic-monitoring/README.md)
3. [Lab 3: Log Management](./lab3-log-management/README.md)
4. [Lab 4: Alerting](./lab4-alerting/README.md)
5. [Lab 5: Advanced Dashboards](./lab5-advanced-dashboards/README.md)
6. [Lab 6: Real-world Payment API Monitoring](./lab6-payment-api/README.md)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/msellamiTN/Grafana-Stack.git
   cd Grafana-Stack/observability-stack
   ```

2. Start the workshop environment:
   ```bash
   docker-compose up -d
   ```

3. Access the services:
   - Grafana: http://localhost:3000 (admin/GrafanaSecure123!Change@Me)
   - Prometheus: http://localhost:9090
   - Alertmanager: http://localhost:9093
   - InfluxDB: http://localhost:8086
   - Payment API: http://localhost:8080/docs
