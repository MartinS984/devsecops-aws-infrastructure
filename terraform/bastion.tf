# 1. Security Group to allow the Bastion to talk to AWS SSM
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-ssm-sg"
  description = "Allow outbound traffic for SSM agent"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-ssm-sg" }
}

# 2. IAM Role for the Bastion
resource "aws_iam_role" "bastion_role" {
  name = "bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 3. Attach the SSM Policy to the Role
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 4. Create the Instance Profile (This was the missing resource!)
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-ssm-profile"
  role = aws_iam_role.bastion_role.name
}

# 5. The Bastion Instance
resource "aws_instance" "bastion" {
  ami           = "ami-0c7217cdde317cfec" # Amazon Linux 2023
  instance_type = "t3.micro"
  subnet_id     = module.vpc.private_subnets[0]
  
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  tags = { Name = "eks-ssm-bastion" }
}

# 6. Define the EKS Describe permission
resource "aws_iam_policy" "bastion_eks_policy" {
  name        = "bastion-eks-describe-policy"
  description = "Allows Bastion to describe EKS clusters for kubeconfig updates"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:DescribeCluster"
        Effect   = "Allow"
        Resource = "*" 
      }
    ]
  })
}

# 7. Attach EKS permission to the Bastion role
resource "aws_iam_role_policy_attachment" "bastion_eks_attach" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_eks_policy.arn
}