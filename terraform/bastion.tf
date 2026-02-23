# Instance to act as a bridge to the private EKS API
resource "aws_instance" "bastion" {
  ami           = "ami-0c7217cdde317cfec" # Amazon Linux 2023 in us-east-1
  instance_type = "t3.micro"
  subnet_id     = module.vpc.private_subnets[0]
  
  # Attach the IAM role that allows SSM access
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name = "eks-ssm-bastion"
  }
}

# IAM Role for SSM access
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

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-ssm-profile"
  role = aws_iam_role.bastion_role.name
}