# Enterprise Supply Chain Data Lakehouse

**A complete end-to-end, event-driven data lakehouse on AWS using S3, Lambda, Iceberg, Glue, Athena, and QuickSight.**

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
|── raw_data/
|    
├── glue_scripts/
│   └── supply_chain_iceberg_job.py   # PySpark ETL using Iceberg
│
├── lambda_functions/
│   ├── lambda_trigger.zip
│   └── lambda_notifier.zip
│
├── athena/
│   ├── views/               # Individual SQL view definitions
│   │   ├── vw_dim_inventory.sql
│   │   ├── vw_dim_orders.sql
│   │   ├── vw_dim_shipments.sql
│   │   ├── vw_dim_suppliers.sql
│   │   ├── vw_dim_warehouses.sql
│   │   ├── vw_fact_inventory.sql
│   │   ├── vw_fact_orders.sql
│   │   ├── vw_fact_shipments.sql
│   │   ├── vw_fact_suppliers.sql
│   │   └── vw_fact_warehouses.sql
│   └── vw_dashboard_master.sql
├── quicksight/              # QuickSight dashboard files & specifications
│   └── Supply_chain_inventory_Quicksight_dashboard.pdf
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


      **Python/PySpark Glue script** :
  
        * Read raw CSV → DataFrame
        * Add ingestion_date
        * writeTo Iceberg (<db>.<folder>).option(auto-merge), partitionedBy ingestion_date
        * on failure → quarantine + archive raw


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
5. **Upload the .csv raw files in the bucket**:

   Ex:

       aws s3 cp inventory792.csv s3://supply-chain-data-lakehouse-53924746****-ap-south-1/raw/inventory/inventory792.csv

       aws s3 cp orders792.csv s3://supply-chain-data-lakehouse-53924746****-ap-south-1/raw/orders/orders792.csv

       aws s3 cp shipment792.csv s3://supply-chain-data-lakehouse-53924746****-ap-south-1/raw/shipments/shipment792.csv

       aws s3 cp supplier792.csv s3://supply-chain-data-lakehouse-53924746****-ap-south-1/raw/suppliers/supplier792.csv

     * Upload it one by one and let the job complete before uploading the next file. Check the job start and success notification.

   
6. **Data Modeling on top of Iceberg Tables using Athena**:

  * Open the athena query editor. Change the workgroup to "supply_chain_wg"
  * fire all the .sql commands from Enterprise Supply Chain Data Lakehouse/athena/views in athena query editor. This will create the data model on top of Iceberg tables.
 
   

7. **Create Quicksight Dashboard**

   * Open Amazon QuickSight, connect to the Glue catalog, and use the `vw_dashboard_master` view.

    
## Quicksight Dashboard

![supply_chain_dashboard_quicksight](https://github.com/user-attachments/assets/9d0b62d4-6c85-4df3-a671-1ea7deb37b38)


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

