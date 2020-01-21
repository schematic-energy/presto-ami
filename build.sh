#!/usr/bin/env bash

set -e

#if [ "$(git status --porcelain)" ]; then
#    echo "Cannot deploy: Git directory not clean"
#    exit 1
#fi

version=`echo $(git rev-list --count HEAD)-$(git rev-parse --short HEAD)`-test

echo "Using:"
echo "PRESTO_AMI_OWNER=$PRESTO_AMI_OWNER"
echo "PRESTO_AMI_ACCOUNTS=$PRESTO_AMI_ACCOUNTS"
echo "PRESTO_AMI_REGIONS=$PRESTO_AMI_REGIONS"
echo "PRESTO_AMI_VPC=$PRESTO_AMI_VPC"
echo "PRESTO_AMI_SUBNET=$PRESTO_AMI_SUBNET"

echo "Building $PRESTO_AMI_ORG/presto-worker-v$version and $PRESTO_AMI_ORG/presto-coordinator-v$version"

packer build  -var "version=$version" packer.json

echo "Built $PRESTO_AMI_ORG/presto-worker-v$version and $PRESTO_AMI_ORG/presto-coordinator-v$version"
