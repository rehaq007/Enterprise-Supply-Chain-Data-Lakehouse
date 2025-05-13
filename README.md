# Enterprise Supply Chain Data Lakehouse

**A complete end-to-end, event-driven data lakehouse on AWS using Iceberg, Glue, Athena, and QuickSight.**

---

## 🎯 Project Overview

This project ingests daily CSV uploads from supply chain (inventory, orders, shipments, suppliers, warehouses) into an **Apache Iceberg** table on **S3**, partitions by ingestion date, automatically catalogs metadata in **AWS Glue**, and serves analytics via **Amazon Athena** and **QuickSight**.

**Key Benefits:**

* Serverless, event-driven pipeline
* ACID-compliant Iceberg tables with schema evolution
* Partition pruning for fast, cost-efficient queries
* Enterprise-grade BI dashboard in QuickSight (live direct query)

---

## 📐 Architecture

![Supply_chain_architecture_diagram drawio](https://github.com/user-attachments/assets/2f4c8e33-1747-4120-8963-039d0c265a7c)


---

## 🔧 Components

1. **S3 Buckets** (`supply-chain-data-lakehouse-...`)

   * `raw/` (incoming CSVs)
   * `processed/` (Iceberg Parquet)
   * `archive/` (raw files post-processing)
   * `quarantine/` (bad records)

2. **EventBridge Rules**

   * **s3-to-glue-trigger** (Object Created on `raw/`) triggers **trigger-glue-on-s3-upload** Lambda
   * **Glue-Job-State-Change** (Glue job SUCCEEDED/FAILED/TIMEOUT) triggers **glue-job-completion-notifier** Lambda

3. **Lambdas**

    **trigger-glue-on-s3-upload**

    * filters raw/... CSVs, starts Glue job, sends SNS "Job Started" message


    **glue-job-completion-notifier**

    * listens to Glue job state change, fetches job args, sends SNS "Job Result" message


4. **Glue ETL Job** (`supply-chain-iceberg-job`)


  ### Python/PySpark Glue script :
  
    1. Read raw CSV → DataFrame
    2. Add ingestion_date
    3. writeTo Iceberg (<db>.<folder>)
       .option(auto-merge), partitionedBy ingestion_date
    4. on failure → quarantine + archive raw


5. **Athena**

   * Database: `supply_chain_db`
   * Iceberg tables: `inventory`, `orders`, `shipments`, `suppliers`, `warehouses`
   * Dimension views: `vw_dim_*`
   * Fact views: `vw_fact_*`
   * **Master view**: `vw_dashboard_master`


6. **QuickSight** (Direct Query)

   * Data source: Athena → `supply_chain_db`
   * Dataset: `vw_dashboard_master` (only one dataset)
   * Visuals: IMP KPIs & Top Products bar chart

---

### 📊 Dashboard KPIs

![supply_chain_dashboard_quicksight](https://github.com/user-attachments/assets/a127d9a7-52d3-4733-baa3-d160c6f8d08f)


---

### 🚀 Getting Started

1. Clone this repo
2. Configure AWS CLI & environment variables (bucket name, Glue job, IAM roles, SNS topic ARN)
3. Deploy infrastructure (CloudFormation/Terraform/CDK) for S3 buckets, Glue job, EventBridge rules, Lambdas, SNS
4. Upload sample CSVs to `raw/inventory/`, etc.
5. Verify logs: Lambda → Glue job → S3 processed
6. In Athena, run the `vw_dashboard_master` creation script
7. In QuickSight, create dataset & build dashboard

---

### 🔑 Why This Project Stands Out

* **True Lakehouse**: Raw zone + Iceberg + Glue Catalog + Athena = modern data platform
* **Event‑Driven**: fully automated via S3 events & EventBridge
* **Scalable & Cost‑Efficient**: partition pruning, serverless compute, direct query
* **Enterprise Ready**: CI/CD deployment, monitoring, SNS alerts, analytics-ready views, stakeholder dashboard

---

*Built by Rehan Qureshi, AWS Data Engineer.*

