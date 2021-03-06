variable "name" {
  description = "The name of the application to launch"
  type        = string
}

variable "environment" {
  description = "The environment to deploy into. Some valid values are production, staging, engineering."
  type        = string
}

variable "service" {
  description = "The name of the service this application is associated with, ie 'send' if the application is 'send-worker'"
  type        = string
}

variable "is_public" {
  description = "Whether the service is public or internal only."
  type        = bool
  default     = false
}

variable "lb_allowed_cidrs" {
  description = "A list of strings of CIDRs to allow inbound to the load balancer"
  type        = list(string)
  default     = []
}

variable "lb_allowed_sgs" {
  description = "A list of strings of Security Group IDs to allow inbound to the load balancer."
  type        = list(string)
  default     = []
}

variable "container_ports" {
  description = "A list of ports the container listens on. Most Mixmax Docker images 'EXPOSE' port 8080."
  type        = list(number)
  default     = [8080]
}

variable "container_name_override" {
  description = "The container name is used for networking the target group to the container instances; set this field to override the container name"
  type        = string
  default     = ""
}

variable "custom_tags" {
  description = "A mapping of custom tags to add to the generated resources."
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "The path the LB will GET to determine if a host is healthy. For example, /health-check  or /status. This health check should only validate that the app itself is online, not necessarily that any downstream dependent services are also online."
  type        = string
  default     = "/health/elb"
}

variable "health_check_grace_period" {
  description = "The load balancer health check grace period in seconds. This defines how long ECS will ignore failing load balancer chcecks on newly instantiated tasks."
  type        = number
  default     = 90
}

variable "task_definition" {
  description = "The task definition family:revision or full ARN to deploy on first run to the Fargate service. If you are deploying software with Jenkins, you can ignore this; this is used with task definitions that are managed in Terraform. If unset, the first run will use an Nginx 'hello-world' task def. Terraform will not update the task definition in the service if this value has changed."
  type        = string
  default     = ""
}

variable "min_capacity" {
  description = "The minimum capacity for a scaling Fargate service."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "The maximum capacity for a scaling Fargate service."
  type        = number
  default     = 8
}

variable "fargate_service_name_override" {
  description = "This parameter allows you to set to the Fargate service name explicitly. This is useful in cases where you need something other than the default {var.name}-{var.environment} naming convention"
  type        = string
  default     = ""
}

variable "alarm_sns_topic_arns" {
  description = "This parameter is a list of the SNS topic ARNs. This is used to send alarm notifications. This is REQUIRED for production deployments!"
  type        = list(string)
  default     = []
}

variable "task_traffic_slow_start" {
  description = "This parameter defines the number of seconds during which a newly registered Fargate task receives an increasing share of the traffic to the target group, giving it time to 'warm up'. This variable is incompatible with the load balancer `least_outstanding_requests` routing algorithm."
  type        = number
  default     = 0
}

variable "cpu_high_threshold" {
  description = "The CPU percentage to be considered 'high' for autoscaling purposes."
  type        = number
  default     = 70
}

variable "cpu_low_threshold" {
  description = "The CPU percentage to be considered 'low' for autoscaling purposes. This was set to a 'safe' value to prevent scaling down when it's not a good idea, but please adjust this higher for your app if possible."
  type        = number
  default     = 30
}

variable "cpu_scaling_enabled" {
  description = "Whether CPU-based autoscaling should be turned on or off"
  type        = bool
  default     = true
}

variable "cloudwatch_evaluation_periods" {
  description = "The number of times a metric must exceed thresholds before an alarm triggers. For example, if `period` is set to 60 seconds, and this is set to 2, a given threshold must have been exceeded twice over 120 seconds."
  type        = number
  default     = 1
}

variable "idle_timeout" {
  description = "The connection idle timeout value for the created load balancer"
  type        = number
  default     = 60
}

variable "set_public_sg_rule" {
  description = "Whether to set the public security group rule allowing all access. This is only used on public load balancers and is useful to set to 'false' if you want to create an internet-facing load balancer that only accepts traffic from certain sources, ie Github -> Jenkins but nothing else over the public internet."
  type        = bool
  default     = true
}

variable "extra_load_balancer_configs" {
  description = "Extra load balancer configurations; used when you want one ECS service fronted by multiple load balancers."
  type        = list(object({ target_group_arn = string, container_name = string, container_port = number }))
  default     = []
}

variable "tls_cert_arns" {
  description = "The ARNs of Amazon Certificate Manager certificates to use with the HTTPS listener on the load balancer. You *must* provide at least one."
  type        = list(string)

  validation {
    condition     = length(var.tls_cert_arns) > 0
    error_message = "You must provide at least one TLS certificate ARN from ACM."
  }
}

variable "service_subnets" {
  description = "A list of subnet IDs to use for instantiating the Fargate service. Tasks will be deployed into these subnets."
  type        = list(string)
}

variable "lb_subnets" {
  description = "A list of subnet IDs to use for instantiating the load balancer."
  type        = list(string)
}

variable "capacity_provider_strategies" {
  description = "The capacity provider (supported by the configured cluster) to use to provision tasks for the service"
  type = list(object({
    capacity_provider = string
    base              = number
    weight            = number
  }))
  default = []
}

variable "load_balancing_algorithm_type" {
  description = "This variable defines if new requests are routed round_robin or least_outstanding_requests"
  default     = "least_outstanding_requests"
  type        = string

  validation {
    condition     = contains(["round_robin", "least_outstanding_requests"], var.load_balancing_algorithm_type)
    error_message = "The only valid values are 'round_robin' or 'least_outstanding_requests'."
  }
}

variable "deployment_maximum_percent" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment."
  type        = number
  default     = 200
}

variable "high_5xx_responses_threshold" {
  description = "The count of 5xx responses per second from the configured load balancer that should trigger alarms"
  type        = number
  default     = 25
}

variable "lb_logs_bucket" {
  description = "The bucket used to store LB logs"
  type        = string
  default     = null
}
