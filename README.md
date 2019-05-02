
# Terraform Consumer Driven Contracts

Generates jsonschema for validating that certain items are present in terraform outputs.

## Dependencies

bash, jq, jsonschema, terraform (and applied config with outputs)

## How To Use 

The easiest way to create a contract is using a pre-existing terraform state. To generate a contract:
1. Fetch the terraform outputs into a file called *tfoutput.json*: `terraform output -json > tfoutput.json`
1. Retrieve the outputs that will be passed into your consumer's config: e.g. `CONSUMED_OUTPUTS="$(terraform-outputs-in-tile-config.sh -o tfoutput.json -c tile.yml)"` to retrieve matching config for an Ops Manager Tile. Since this is an automated, if any variables in the tile config don't exactly match, they will be missed.  
1. Validate that the desired outputs are set in the output (*CONSUMED_OUTPUTS*), formatted as a JSON list
1. Run `create-tfoutput-jsonschema.sh -o "$CONSUMED_OUTPUTS"  > schema-$CONSUMER.json ` to create the contract in the form of a JSON schema. you should define `$CONSUMER` as a name to identify the purpose of the config file (*tile.yml*) that you used in a previous step.

For subsequent terraform runs, you can check the contract is adhered to by running a standard JSON schema validation tool e.g. `jsonschema -i schema.json schema-$CONSUMER.json`

If you are using the Concourse Terraform Resource, this deosn't publish Terraform outputs in their raw form, you should use the alternative schema creation script `create-tfconcourse-jsonschema.sh` for schemas to test the output.

## Why?

Terraform can be used for a number of things, but it is most suited to deploying things at the infrastructure layer. When we come to the application layer, there might be a number of platforms, data services or even regular old applications that need to be configured with details of the infrastructure that they run in. I.e. the infrastructure provisioned with terraform.

Therefore outputs produced by running our terraform configs are relied on by a multiple consumers. This means that whenever we want to evolve our terraform - for a number of reasons, terraform configs do need to change over time - we should know that the change will not break one of our consumers. The concept of "Consumer Driven Contracts" - commonly used in microservices to ensure that a producer-service for an API can make changes  without impacting consumer-services - can be used to ensure that we can evolve our terraform scripts without impacting services running on that infrastructure.

## Contracts

The contract of services with terraform is different than the Contracts that microservices have with each other. We don't rely on HTTP but only on the output format from terraform, which is (can be) a JSON with a number of outputs specified within it. We also (ultimately) rely on a connection to some form of object store being available, which is where terraform holds its outputs (and more generally, its state).

Since we are relying on fields being present in a JSON, there is a standard way to design a contract: jsonschema. In this scripts we use it in its simplest form: to describe which fields are required on JSON objects. There is much more jsonschema can do. 

The fundamental idea of consumer driven contracts is that each consumer defines its own contract, covering only the parts of the interface that it uses. For different consumers these contracts may be different, and summed across all consumers this may not cover the whole of the API. So the producer knows which fields are not actively being used by consumers, which can be changed at will. Fields that are in use but which should be changed require a migration strategy (e.g. adding the new field and asking clients to switch some time before deleting the old field).

## Extentions

### Triggering

With schema we can show when our deployment automation (consuming terraform values) needs updating, it does not take care of when the values change and we just need to trigger again. We could also use the consumer contracts to tell the consumers precisely when the values they consume have been updated

