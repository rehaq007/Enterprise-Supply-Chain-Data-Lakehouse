import sys, boto3
from datetime import datetime
from pyspark.context import SparkContext
from pyspark.sql.functions import current_date
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions

# 1) Bootstrap
args = getResolvedOptions(sys.argv,
    ['JOB_NAME','bucket','key','glue_database_name'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# 2) Paths
bucket  = args['bucket']
key     = args['key']        # raw/<folder>/<file>.csv
db_name = args['glue_database_name']
folder  = key.split('/')[1]
today   = datetime.utcnow().strftime('%Y-%m-%d')
raw_s3    = f"s3://{bucket}/{key}"
processed = f"s3://{bucket}/processed/{folder}"
quarantine= f"s3://{bucket}/quarantine/{folder}"

# 3) Read + transform
df = (spark.read
        .option("header","true")
        .option("inferSchema","true")
        .csv(raw_s3)
        .withColumn("ingestion_date", current_date()))

# 4) Ensure namespace
spark.sql(f"CREATE NAMESPACE IF NOT EXISTS glue_catalog.{db_name}")

# 5) Write with auto-schema evolution
try:
    (df.writeTo(f"glue_catalog.{db_name}.{folder}")
       .option("write.schema.auto-merge.enabled","true")
       .option("write.parquet.compression-codec","snappy")
       .option("write.distribution-mode","hash")
       .partitionedBy("ingestion_date")
       .createOrReplace())
    print(f"[INFO] Wrote Iceberg table: {db_name}.{folder}")
except Exception as e:
    print(f"[ERROR] Write failed, sending to quarantine: {e}")
    df.write.mode("overwrite").parquet(f"{quarantine}/bad_{today}.parquet")
    raise

# 6) Archive raw
s3 = boto3.resource("s3")
s3.Object(bucket, key.replace("raw/","archive/")).copy_from(CopySource={'Bucket':bucket,'Key':key})
s3.Object(bucket, key).delete()
print("[INFO] Archived raw file")

job.commit()
