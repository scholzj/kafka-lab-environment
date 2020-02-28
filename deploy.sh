#!/usr/bin/env bash

#####
# Change these options to modify the installation
#####

# Namespace where the Stirmzi operator and Kafka lcuster will be installed
CLUSTER_NAMESPACE=kafka
# Name of the Kafka cluster
CLUSTER_NAME=lab
# Authentication mechanism used for the lab users
# Supported options are tls and scram-sha-512
# When using TLS, you have to disable the plain listener in 01-kafka/kafka.yaml
AUTHENTICATION=scram-sha-512
#Number of user environments
USERS=10

#####
# Deployment of the lab Kafka cluster
#####

# Create the namespace
kubectl create namespace $CLUSTER_NAMESPACE

# Deploy the cluster operator
echo "Deploying Strimzi operator"
cat 01-kafka/strimzi-cluster-operator.yaml \
  | gsed "s/namespace: .*/namespace: $CLUSTER_NAMESPACE/" \
  | kubectl apply -f - -n $CLUSTER_NAMESPACE 

# Deploy the Kafka cluster
echo "Deploying Kafka cluster"
eval "echo \"$(cat 01-kafka/kafka.yaml)\"" \
  | kubectl apply -f - -n $CLUSTER_NAMESPACE

# Wait for the cluster to be ready
echo "Waiting for 5 minutes for a Kafka cluster to be ready"
kubectl wait kafka/$CLUSTER_NAME --for=condition=Ready --timeout=300s -n $CLUSTER_NAMESPACE 

#####
# Create the user environments
#####

# Create environment for each user
for ENVIRONMENT in $(seq 1 $USERS)
do
  echo "Creating user $ENVIRONMENT"
  ID=$(printf "%03d" $ENVIRONMENT)
  USERNAME="user-$ID"
  USER_NAMESPACE="user-$ID"

  # Create user namespace
  echo "Creating user namespace"
  kubectl create namespace $USER_NAMESPACE

  # Create Kafka resources
  echo "Applying resources"
  eval "echo \"$(gsed -s '1i---' 02-user-env-template/*)\"" \
    | kubectl apply -f -

  # Copy Cluster TLS secret and user secret
  echo "Copying secrets"
  kubectl get secret $CLUSTER_NAME-cluster-ca-cert --namespace=$CLUSTER_NAMESPACE --export -o yaml \
    | kubectl apply --namespace=$USER_NAMESPACE -f -
  kubectl get secret $USERNAME --namespace=$CLUSTER_NAMESPACE --export -o yaml \
    | kubectl apply --namespace=$USER_NAMESPACE -f -
done