#!/bin/bash

bucket="gs://spark-buket"
template_name="mysql-flights-import"
cluster_name="sqoop-import"
instance_name="streaming-project-236115:us-central1:myinstance"
table_name="flights"

#gsutil rm -r $bucket/$table_name && 

gcloud dataproc workflow-templates delete -q $template_name  &&

gcloud beta dataproc workflow-templates create $template_name &&

gcloud beta dataproc workflow-templates set-managed-cluster $template_name --zone "us-east1-b" \
--cluster-name=$cluster_name \
 --scopes=default,sql-admin \
 --initialization-actions=gs://dataproc-initialization-actions/cloud-sql-proxy/cloud-sql-proxy.sh \
 --properties=hive:hive.metastore.warehouse.dir=$bucket/hive-warehouse \
 --metadata=enable-cloud-sql-hive-metastore=false \
 --metadata=additional-cloud-sql-instances=$instance_name=tcp:3307 \
 --master-machine-type n1-standard-1 \
 --master-boot-disk-size 20 \
  --num-workers 2 \
--worker-machine-type n1-standard-2 \
--worker-boot-disk-size 20 \
--image-version 1.2 &&

gcloud beta dataproc workflow-templates add-job hadoop \
--step-id=flights_test_data \
--workflow-template=$template_name \
--class=org.apache.sqoop.Sqoop \
--jars=$bucket/sqoop-jars/sqoop_sqoop-1.4.7.jar,$bucket/sqoop-jars/sqoop_avro-tools-1.8.2.jar,\
file:///usr/share/java/mysql-connector-java-5.1.42.jar \
-- eval -Dmapreduce.job.user.classpath.first=true \
--driver com.mysql.jdbc.Driver \
--connect="jdbc:mysql://localhost:3307" \
--username=root --password=Siddharth88!@ \
--query "select count(*) from airports.flights where 1=1 and \$CONDITIONS limit 100" \

gcloud beta dataproc workflow-templates instantiate $template_name
