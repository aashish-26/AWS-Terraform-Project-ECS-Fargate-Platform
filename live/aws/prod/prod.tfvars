# prod.tfvars
# Example variable values for the prod environment.
# Replace placeholders (like account_id and AMI ID) with real values before running plan/apply.

project     = "infra-project"
environment = "prod"
region      = "ap-south-1"
account_id  = "471112729537"

cidr_vpc       = "10.30.0.0/16"
public_subnets = ["10.30.0.0/24", "10.30.1.0/24"]
azs            = ["ap-south-1a", "ap-south-1b"]

image = "471112729537.dkr.ecr.ap-south-1.amazonaws.com/infra-project-prod-app:latest"

task_cpu       = 256
task_memory    = 512
desired_count  = 2
container_port = 80

db_instance_type       = "t3.micro"
db_ami_id              = "ami-0d176f79571d18a8f" # TODO: replace with an Amazon Linux 2 AMI ID in ap-south-1
db_name                = "appdb"
db_username            = "appuser"
db_data_volume_size_gb = 20

alarm_email = "abhandari.2002@gmail.com"


