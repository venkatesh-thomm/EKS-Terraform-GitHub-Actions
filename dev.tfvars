env                   = "dev"
aws-region            = "us-east-1"
vpc-cidr-block        = "10.16.0.0/16"
vpc-name              = "vpc"
igw-name              = "igw"
pub-subnet-count      = 3
pub-cidr-block        = ["10.16.0.0/20", "10.16.16.0/20", "10.16.32.0/20"]
pub-availability-zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pub-sub-name          = "subnet-public"
pri-subnet-count      = 3
pri-cidr-block        = ["10.16.128.0/20", "10.16.144.0/20", "10.16.160.0/20"]
pri-availability-zone = ["us-east-1a", "us-east-1b", "us-east-1c"]
pri-sub-name          = "subnet-private"
public-rt-name        = "public-route-table"
private-rt-name       = "private-route-table"
eip-name              = "elasticip-ngw"
ngw-name              = "ngw"
eks-sg                = "eks-sg"



# EKS
is-eks-cluster-enabled  = true
cluster-version         = "1.34"
cluster_name            = "eks-cluster"
endpoint-private-access = true
endpoint-public-access  = true # Set to true if you want to access the cluster endpoint over the public internet. If false, the cluster endpoint will only be accessible from within the VPC. 
ondemand_instance_types = ["m7i-flex.large"]
spot_instance_types     = ["c7i-flex.large", "m7i-flex.large", "t3.micro"]
# On-demand (base)
desired_capacity_on_demand = "1"
min_capacity_on_demand     = "1"
max_capacity_on_demand     = "2"

# Spot (autoscaling test)
desired_capacity_spot = "0"
min_capacity_spot     = "0"
max_capacity_spot     = "2"
addons = [
  {
    name    = "vpc-cni",
    version = "v1.20.0-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.2-eksbuild.4"
  },
  {
    name    = "kube-proxy"
    version = "v1.33.0-eksbuild.2"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.46.0-eksbuild.1"
  }
  # Add more addons as needed
]

