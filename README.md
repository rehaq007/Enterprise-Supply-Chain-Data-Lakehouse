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

## 📂 Repository Structure

```
Enterprise-Supply-Chain-Data-Lakehouse
├── terraform/
│   ├── main.tf             # Core infra: S3, Glue, Lambda, EventBridge, Athena
│   ├── variables.tf        # Terraform variables
│   ├── outputs.tf          # Outputs
│   └── terraform.tfvars    # stores all the values of the variables. #IMP - Please update all the values before running the terraform sripts
│   
|── Raw_Data/
|    
├── glue_scripts/
│   └── supply_chain_iceberg_job.py   # PySpark ETL using Iceberg
│
├── lambda_functions/
│   ├── lambda_trigger.zip
│   └── lambda_notifier.zip
│
├── sql/
│   ├── views/
│   │   ├── vw_inventory_summary.sql
│   │   ├── vw_order_trends.sql
│   │   ├── vw_shipment_status.sql
│   │   ├── ... (total 10 view scripts)
│   │   └── vw_dashboard_master.sql    # Master dashboard view
│
└── README.md               # High-level overview & instructions

```

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


## 🚀 Getting Started

1. **Clone the repo**:

   ```bash
   git clone https://github.com/rehaq007/Enterprise-Supply-Chain-Data-Lakehouse.git
   cd Enterprise-Supply-Chain-Data-Lakehouse/terraform
   ```

2. **Upload Lambda ZIPs and Glue script**:

   ```bash
   aws s3 cp ../lambda_functions/lambda_trigger.zip s3://<your-code-bucket>/lambdas/
   aws s3 cp ../lambda_functions/lambda_notifier.zip s3://<your-code-bucket>/lambdas/

   aws s3 cp ../glue_scripts/supply_chain_iceberg_job.py s3://<your-code-bucket>/glue_scripts/supply_chain_iceberg_job.py"
   
   ```

3. **Update terraform.tfvars with your values**

   ```bash
   account_id                  = "5392474*****"
   data_bucket                 = "supply-chain-data-lakehouse-5392474*****-ap-south-1"
   code_bucket                 = "my-code-bucket-5392474*****-ap-south-1"
   lambda_code_s3_key_trigger  = "lambdas/lambda_trigger.zip"
   lambda_code_s3_key_notifier = "lambdas/lambda_notifier.zip"
   glue_script_s3_path         = "s3://my-code-bucket-5392474*****-ap-south-1/glue_scripts/supply_chain_iceberg_job.py"
   notification_email          = "rehanq****@gmail.com"
   ```

4. **Bootstrap Terraform**:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Data Modeling on top of Iceberg Tables using Athena**:

   ```bash
   for f in ../sql/views/*.sql; do
     aws athena start-query-execution --work-group supply-chain-wg \
       --query-string "$(< "$f")";
   done
   ```

5. **View Dashboard**:

   * Open Amazon QuickSight, connect to the Glue catalog, and use the `vw_dashboard_master` view.

---

## 🛠️ Tech Stack

* **Infra**: Terraform on AWS (S3, Glue, Lambda, EventBridge, Athena, SNS)
* **ETL**: PySpark with Iceberg
* **Analytics**: Athena SQL (+ Iceberg time travel views)
* **BI**: Amazon QuickSight

---

## This repo showcases:

* Production-grade architecture design
* Infrastructure as code best practices
* Event-driven, serverless pipelines
* Advanced data modeling with Iceberg
* Automated notifications and monitoring
* Self-service analytics with Athena & QuickSight

---

### 🔑 Why This Project Stands Out

* **True Lakehouse**: Raw zone + Iceberg + Glue Catalog + Athena = modern data platform
* **Event‑Driven**: fully automated via S3 events & EventBridge
* **Scalable & Cost‑Efficient**: partition pruning, serverless compute, direct query
* **Enterprise Ready**: CI/CD deployment, monitoring, SNS alerts, analytics-ready views, stakeholder dashboard

---

*Built by Rehan Qureshi, AWS Data Engineer.*

