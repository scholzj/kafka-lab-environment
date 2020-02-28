# Apache Kafka lab environment using Strimzi

This is a simple tooling to deploy Apache Kafka cluster using Strimzi as a lab environment.
It does following:
* Deploys Strimzi
* Deploys Apache Kafka cluster
* Creates the user environments as separate namespaces

The Strimzi operator and Kafka cluster are installed through YAML files in `01-kafka`.

The user environments are deployed using the templates in `02-user-env-template`.
By default the template will create a user names `user-XXX` where `XXX` is `001`, `002` etc. depending on the number of evironments.
Currently the template in this repository contains following resources:
* Topic named `user-XXX` (the topic name is the same as user name)
* The Kafka user with the name `user-XXX`
    * The user has automatically ACLs to use topics with name starting with `user-XXX`
    * The user has automatically quota setup to read / write up to 1MB/s and use up to 10 percent of the request handler.
* A Kubernetes namespace names `user-XXX` (the topic name is the same as user name)

After the user is created, the secret with the credentials and the secret with the broker TLS public key are copied into the user namespace.

Lab users can use their namespace and connect to the cluster on `lab-kafka-bootstrap.kafka.svc:9092` or `lab-kafka-bootstrap.kafka.svc:9093` with TLS encryption.

## Creating the lab environment

To create the lab environment, run the `./deploy.sh` script.

## Customizations

You can customize this tooling by:
* Drop in your own version of Strimzi or AMQ Streams depending on your lab (replace the `01-kafka/strimzi-cluster-operator.yaml` file)
* Fine-tune the Kafka cluster in `01-kafka/kafka.ymal` to correspond to what you expect the users to do (the current version is designed for my Minishift, so resources might need some tuning ;-))
* Adding more resources to the `02-user-env-template` directory
* Modifying the environment variables on the beginning of the `deploy.sh` script
    * `CLUSTER_NAMESPACE` defines the namespace where the KAfka cluster will be deployed
    * `CLUSTER_NAME` defines the name of the Kafka cluster
    * `AUTHENTICATION` defines the authentication type
    * `USERS` defines the number of user environments created

## Requirements

This has been tested and probably works right now only on MacOS.
Following tools are expected to be installed (which are not present by default):

* kubectl
* GNU sed (`brew install gnu-sed` as `gsed`)