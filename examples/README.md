This example configures a DC/OS cluster and then showcases the following demo:
https://github.com/dcos/demos/tree/master/fastdata-iot/1.11

```
terraform init
export LINODE_TOKEN=... 
terraform apply
# Install the DC/OS CLI
eval $(terraform output install_cli)
dcos package install --yes spark
dcos package install --yes cassandra
dcos cassandra endpoints native-client
dcos job add cassandra-schema.json
dcos job run init-cassandra-schema-job
dcos package install --yes kafka
dcos marathon app add akka-ingest.json
dcos spark run --submit-args='--driver-cores 0.1 --driver-memory 1024M --total-executor-cores 4 --class de.nierbeck.floating.data.stream.spark.KafkaToCassandraSparkApp https://oss.sonatype.org/content/repositories/snapshots/de/nierbeck/floating/data/spark-digest_2.11/0.2.1-SNAPSHOT/spark-digest_2.11-0.2.1-SNAPSHOT-assembly.jar METRO-Vehicles node-0-server.cassandra.autoip.dcos.thisdcos.directory:9042 broker.kafka.l4lb.thisdcos.directory:9092'
dcos marathon app add dashboard.json

open http://$(terraform output public_agent_public_ips | cut -f1):8000

```
