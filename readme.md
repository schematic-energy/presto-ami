# Presto AMI Builder

This repository is a [Packer](https://www.packer.io/) project that
builds AWS AMIs for a Presto Worker and Coordinator nodes.

Presto runs on port `8080` on the coordinators and the workers.

The coordinator image also runs a Hive server on port 10000. Note that
that the worker nodes do _not_ run Hive; as such, the Hive cluster is
not suitable for running actual data queries. Hive is intended only to
be used for DDL transactions, with Presto handling actual queries.

This configuration is also intended only for use with S3 or some other
external storage; it does not define any distributed storage on the
cluster itself.

Note: These AMIs could be used standalone, but are intended to be used
with Schematic Energy's
[Scio](https://github.com/schematic-energy/scio) project, a
Pulumi-based AWS install script.

## Building the AMIs

Export the following environment variables:

- `PRESTO_AMI_ORG` - The organization name, used to name the AMIs (e.g, "schematic-energy")
- `PRESTO_AMI_OWNER` - The AWS account ID of the AMI owner
- `PRESTO_AMI_ACCOUNTS` - Comma-separated list of AWS account IDs that will have access to the AMIs.
- `PRESTO_AMI_REGIONS` - Regions in which the AMI will be made available.
- `PRESTO_AMI_VPC` - The AWS VPC id for Packer to use to build the AMI.
- `PRESTO_AMI_SUBNET` - The AWS Subnet id for Packer to use to build the AMI.
- `DATOMIC_DIST_FILE` - Path to the Datomic distribution .zip file on
  the local filesystem.

Your environment must also be configured with AWS credentials with
permissions in the specified accounts, VPC and subnet.

Then, run `./build.sh` and wait for the installation to
complete. Build status and the names and AMI ids of the completed
images will be printed to stdout.

## Running Presto

(Note: if you are using the Scio installation scripts, you can skip
this section: all these details are implemented in that project's
Pulumi code)

The built in Hive server expects a Postgres RDS instance to use as
it's Metastore database, with a database name of `hive` and a username
of `hive`. The hostname of the Metastore db is expected to be
available as an SSM String parameter named
`/scio/<environment>/hive-metastore/host`, and the to the `hive` user as an
SSM SecureString at `/scio/<environment>/hive-metastore/password`.

The database may be empty: each time the Coordinator node is started,
it will check that the required schema is available and add it if it
hasn't been already.

The environment name is an arbitrary string that allows multiple
instances of the cluster to be run in the same AWS account.

After ensuring that you have a Hive Metastore as described above, to
run a Presto cluster,launch EC2 instances using the generated AMI and
run the `/home/ec2-user/run.sh` script after launch (EC2 User Data
scripts are a good way to do this.) The `run.sh` script takes two
arguments: the environment name and an S3 path indicating the location
of the Presto cluster's configuration (see next section).

## Configuring Presto

Presto configuration is stored in S3, with separate configurations
paths for the worker and coordinator nodes. Every time a node is
started with the `run.sh` script, it downloads all the files with the
given S3 prefix and adds them to `$PRESTO_HOME/etc`.

As described in the Presto documentation, a typical installation will
need to define at least the following files in S3:

```
jvm.config
config.properties
node.properties
catalog/hive.properties
```

Note: for worker nodes, the `config.properties` file contains the
`discovery.uri` property used to locate the coordinator node. As such,
you will either need to use DNS to map a stable name to the
coordinator instance, or update the config file with the correct
coordinator IP.

To make configuration changes, simply upload the new configuration
files to S3. The changes will not take effect until Presto is
restarted. To restart Presto, you can either restart the entire EC2
instances, or use a HTTP service provided on each instance at
`http://<host>:80/cgi-bin/update-config.sh`. Executing this script
will download the new config from S3, and restart the Presto process
so it takes effect.

## Important: Security

The setup for this project assumes that the entire cluster is running
on a trusted private subnet or security group. Exposing any of the
nodes directly to incoming traffic internet is extremely *not*
reccomended. The default configuration of this project assumes that
anyone with network access to the nodes is able to connect to Presto,
run queries, and restart nodes.

To set up something more restrictive, you will need to:

- Configure Presto's authentication mechanisms
- Use VPNs, NLBs or firewall whitelists to restrict network access

This project may provide some utilities for this, in the future.
