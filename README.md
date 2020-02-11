# `terraform-aws-fargate-service-with-lb`

This module is an opinionated implementation of a Fargate service with an application load balancer, serving HTTP requests. This is useful for creating an API or web service.

It fronts all traffic with HTTPS on port 443, forwarding to the configured `container_ports` (default is 80.) This module outputs the ALB DNS name, which can be used to create a CNAME record in Route 53.

For creating a Fargate service without a built-in application load balancer, see the [terraform-aws-fargate-service module](https://github.com/mixmaxhq/terraform-aws-fargate-service). This is also useful when deploying an application behind a Network Load Balancer.

## Usage

An example deployable application can be found in the [examples/simple](examples/simple) directory.

## Notes

This module creates security groups (ie firewalls) for communicating with both the load balancer, and the service over the network. By default, it allows all traffic originating from the container (in other words, all `egress` traffic is allowed), and inbound traffic from the load balancer to the container on port 80 (or whatever `container_ports` is set to.) However, if you would like to communicate inbound to the load balancer from another service, you must create an [`aws_security_group_rule`](https://www.terraform.io/docs/providers/aws/r/security_group_rule.html) resource referencing the load balancer's security group. The module-created security group is available as the output `lb_sg_id`.

Additionally, this module creates an IAM role for the Fargate service to authorize access to AWS resources. By default, these services get no permissions. To add permissions to an AWS resource, create an [`aws_iam_policy` resource](https://www.terraform.io/docs/providers/aws/r/iam_policy.html) and [attach the policy to the role using an `aws_iam_role_policy_attachment` resource](https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html). The module-created IAM role name is available as the output `task_role_name` from the module.

## Gotchas

### Container does not exist in the task definition
If you get an error like below,
```
Error: InvalidParameterException: The container module-test-staging does not exist in the task definition.
        status code: 400, request id: a1c206cc-c593-455c-8ac2-b198956e9447 "module-test-staging"
  on .terraform/modules/web.fargate_service/main.tf line 28, in resource "aws_ecs_service" "service":
  28: resource "aws_ecs_service" "service" {
```

This is due to this module making some assumptions about the name of the container to [connect networking for the load balancer](https://github.com/mixmaxhq/terraform-aws-fargate-service-with-lb/blob/master/main.tf#L14). The default is set to `${var.name}-${var.environment}` when deploying a task definition using the `mixmax` CLI. However, you can override this behavior. Find the `name` value in your task definition's [container definition](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_name), and set the `container_name_override` parameter to this module for overriding the name used.

## How are the docs generated?

Manually with [`terraform-docs`](https://github.com/segmentio/terraform-docs), something like this:
```
terraform-docs md document . >> README.md
# and then edit out the old stuff
```

## Variables

### Required Variables

The following variables are required:

#### environment

Description: The environment to deploy into. Some valid values are production, staging, engineering.

Type:
`string`

#### name

Description: The name of the application to launch

Type:
`string`

#### service

Description: The name of the service this application is associated with, ie 'send' if the application is 'send-worker'

Type:
`string`

### Optional Variables

The following variables are optional (have default values):

#### container\_name\_override

Description: The container name is used for networking the target group to the container instances; set this field to override the container name

Type:
`string`

Default:
`""`

#### container\_ports

Description: A list of ports the container listens on. Default is port 80

Type:
`list(number)`

Default:
```json
[
  80
]
```

#### custom\_tags

Description: A mapping of custom tags to add to the generated resources.

Type:
`map(string)`

Default:
`{}`

#### health\_check\_path

Description: The path the LB will GET to determine if a host is healthy. For example, /health-check  or /status. This health check should only validate that the app itself is online, not necessarily that any downstream dependent services are also online.

Type:
`string`

Default:
`"/"`

#### is\_public

Description: A boolean describing if the service is public or internal only.

Type:
`bool`

Default:
`false`

#### lb\_allowed\_cidrs

Description: A list of strings of CIDRs to allow inbound to the load balancer

Type:
`list(string)`

Default:
`[]`

#### lb\_allowed\_sgs

Description: A list of strings of Security Group IDs to allow inbound to the load balancer. The bastion is allowed by default.

Type:
`list(string)`

Default:
`[]`

#### task\_definition

Description: The task definition family:revision or full ARN to deploy on first run to the Fargate service. If you are deploying software with Jenkins, you can ignore this; this is used with task definitions that are managed in Terraform. If unset, the first run will use an Nginx 'hello-world' task def. Terraform will not update the task definition in the service if this value has changed.

Type:
`string`

Default:
`""`

## Outputs

The following outputs are exported:

#### alb\_dns\_name

Description: The DNS name of the created ALB. Useful for creating a CNAME from mixmax.com DNS names.

#### cloudwatch\_log\_group\_name

Description: The name of the CloudWatch log group

#### lb\_sg\_id

Description: The ID of the Security Group attached to the LB

#### task\_role\_arn

Description: The ARN of the IAM Role created for the Fargate service

#### task\_sg\_id

Description: The ID of the Security Group attached to the ECS tasks

