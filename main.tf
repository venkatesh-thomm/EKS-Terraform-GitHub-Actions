locals {
  org = "ap-medium"
  env = var.env
}

data "aws_eks_cluster" "cluster" {
  name       = "${local.env}-${local.org}-${var.cluster_name}"
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = "${local.env}-${local.org}-${var.cluster_name}"
  depends_on = [module.eks]
}

resource "aws_iam_role" "cluster_autoscaler" {
  name = "cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
    }]
  })
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  role = aws_iam_role.cluster_autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  depends_on = [module.eks]

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = "dev-ap-medium-eks-cluster"
    },
    {
      name  = "awsRegion"
      value = "us-east-1"
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.cluster_autoscaler.arn # Ensure this role exists!
    }
  ]
}

provider "helm" {
  kubernetes = {
    host = data.aws_eks_cluster.cluster.endpoint

    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.cluster.certificate_authority[0].data
    )

    token = data.aws_eks_cluster_auth.cluster.token
  }
}

module "eks" {
  source = "./module"

  env                   = var.env
  cluster_name          = "${local.env}-${local.org}-${var.cluster_name}"
  cidr-block            = var.vpc-cidr-block
  vpc-name              = "${local.env}-${local.org}-${var.vpc-name}"
  igw-name              = "${local.env}-${local.org}-${var.igw-name}"
  pub-subnet-count      = var.pub-subnet-count
  pub-cidr-block        = var.pub-cidr-block
  pub-availability-zone = var.pub-availability-zone
  pub-sub-name          = "${local.env}-${local.org}-${var.pub-sub-name}"
  pri-subnet-count      = var.pri-subnet-count
  pri-cidr-block        = var.pri-cidr-block
  pri-availability-zone = var.pri-availability-zone
  pri-sub-name          = "${local.env}-${local.org}-${var.pri-sub-name}"
  public-rt-name        = "${local.env}-${local.org}-${var.public-rt-name}"
  private-rt-name       = "${local.env}-${local.org}-${var.private-rt-name}"
  eip-name              = "${local.env}-${local.org}-${var.eip-name}"
  ngw-name              = "${local.env}-${local.org}-${var.ngw-name}"
  eks-sg                = var.eks-sg

  is_eks_role_enabled           = true
  is_eks_nodegroup_role_enabled = true
  ondemand_instance_types       = var.ondemand_instance_types
  spot_instance_types           = var.spot_instance_types
  desired_capacity_on_demand    = var.desired_capacity_on_demand
  min_capacity_on_demand        = var.min_capacity_on_demand
  max_capacity_on_demand        = var.max_capacity_on_demand
  desired_capacity_spot         = var.desired_capacity_spot
  min_capacity_spot             = var.min_capacity_spot
  max_capacity_spot             = var.max_capacity_spot
  is-eks-cluster-enabled        = var.is-eks-cluster-enabled
  cluster-version               = var.cluster-version
  endpoint-private-access       = var.endpoint-private-access
  endpoint-public-access        = var.endpoint-public-access

  addons = var.addons

}
