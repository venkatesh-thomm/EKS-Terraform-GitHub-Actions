# Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow Inound  access to private subnets"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] ## My IP FROM LATPTOP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}


# Get the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Instance Profile (MANDATORY for EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}


# EC2 INSTANCE [ CONNECT USING SH MANAGER]
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public-subnet[0].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  # Attach IAM Profile to Bastion EC2
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  tags = {
    Name = "bastion"
    env  = var.env
  }
}

resource "aws_security_group_rule" "bastion_to_eks_nodes" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id # <- use this SG
  source_security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks-cluster-sg.id
  source_security_group_id = aws_security_group.bastion_sg.id
}


# IAM Role for SSM
resource "aws_iam_role" "bastion_ssm_role" {
  name = "bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AmazonSSMManagedInstanceCore policy
resource "aws_iam_role_policy_attachment" "bastion_ssm_policy" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# Add EKS Describe permission to allow the bastion host to query EKS cluster details
resource "aws_iam_policy" "bastion_eks_describe" {
  name = "bastion-eks-describe"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_eks_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = aws_iam_policy.bastion_eks_describe.arn
}

resource "aws_eks_access_entry" "bastion_access" {
  cluster_name  = aws_eks_cluster.eks[0].name
  principal_arn = aws_iam_role.bastion_ssm_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = aws_eks_cluster.eks[0].name
  principal_arn = aws_iam_role.bastion_ssm_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
