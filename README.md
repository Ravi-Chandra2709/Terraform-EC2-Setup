# **Terraform Setup and Deployment Guide**

## ** Introduction**
Terraform is an Infrastructure as Code (IaC) tool that allows you to define, provision, and manage cloud resources using declarative configuration files. This guide will walk you through installing Terraform on macOS, setting up AWS credentials, writing Terraform scripts, and deploying an EC2 instance with appropriate IAM permissions.

---

## ** Prerequisites**
Before you begin, ensure you have the following:
- An **AWS Free Tier account** ([Sign up here](https://aws.amazon.com/free/))
- **AWS CLI installed** and configured
- **Terraform installed on macOS**

---

## ** Installing Terraform on macOS**
Terraform can be installed using **Homebrew**:
```sh
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verify installation:
```sh
terraform version
```
 If installed correctly, this will display the Terraform version.

---

## **Configuring AWS CLI**
To authenticate Terraform with AWS, configure AWS CLI:
```sh
aws configure
```
Provide:
- **AWS Access Key ID**
- **AWS Secret Access Key**
- **Default region** (e.g., `us-east-1`)
- **Default output format** → Leave blank or enter `json`

Verify setup:
```sh
aws sts get-caller-identity
```
 This should return your AWS account details.

---

## ** Creating an IAM Policy for Terraform**
To allow Terraform to manage EC2 and IAM roles, we create a **custom IAM policy** and attach it to our IAM user.

### **Step 1: Create the policy manually in AWS Console**
- Navigate to **AWS Console → IAM → Policies → Create Policy**
- Choose **JSON** and paste the following:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:RunInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceTypes",
                "ec2:DescribeKeyPairs",
                "ec2:CreateKeyPair",
                "ec2:DeleteKeyPair",
                "ec2:ImportKeyPair",
                "ec2:CreateSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:CreateTags",
                "ec2:DescribeTags",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeVolumes",
                "ec2:DescribeInstanceCreditSpecifications"
            ],
            "Resource": "*"
        }
    ]
}
```
- Save this policy as **TerraformEC2Policy** and attach it to your IAM user.
- Click Next → Name the policy → Create Policy.

### **Explanation of IAM Policy**
- **ec2:RunInstances**	Allows launching EC2 instances
- **ec2:TerminateInstances**	Allows deleting EC2 instances
- **ec2:DescribeInstances**	Allows Terraform to check EC2 details
- **ec2:DescribeInstanceType**s	Required for selecting an EC2 instance type (e.g., t2.micro)
- **ec2:DescribeKeyPairs**	Allows listing available key pairs
- **ec2:CreateKeyPair**	Enables creating an SSH key pair
- **ec2:DeleteKeyPair**	Allows deleting a key pair
- **ec2:ImportKeyPair**	Allows importing an SSH key pair to AWS
- **ec2:CreateSecurityGroup**	Allows creating security groups for EC2
- **ec2:DescribeSecurityGroups**	Enables listing security groups
- **ec2:AuthorizeSecurityGroupIngress**	Allows setting inbound security rules
- **ec2:AuthorizeSecurityGroupEgress**	Allows setting outbound security rules
- **ec2:RevokeSecurityGroupEgress**	Enables removing default egress rules
- **ec2:DeleteSecurityGroup**	Allows deleting security groups
- **ec2:CreateTags**	Allows tagging AWS resources
- **ec2:DescribeTags**	Enables viewing existing tags on resources
- **ec2:DescribeInstanceAttribute**	Allows checking instance attributes (e.g., root volume size)
- **ec2:DescribeVolumes**	Required for checking instance storage volumes
- **ec2:DescribeInstanceCreditSpecifications**	Needed for T-series instance types like t2.micro

I was exploring different available policies and created this JSON. However, if preferred, you can simply grant full access by using the policy below:
- **ec2:'*'** → Grants full access to EC2 resources (instances, key pairs, security groups, etc.).

### **Which User Needs This Policy?**
- The policy should be attached to the **IAM user that is running Terraform**.
- You can find your IAM user by running:
  ```sh
  aws sts get-caller-identity
  ```
  This will return the **IAM ARN** of the user.
- Then, in the **AWS Console**, go to **IAM → Users → Select your user → Attach Policy**.

---

## ** Understanding `main.tf` - Terraform Configuration File**

This script creates an **EC2 instance** with an **SSH key pair** and a **security group** allowing SSH and HTTP/HTTPS access.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.36"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Create an EC2 Security Group
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow SSH, HTTP, and HTTPS inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### **Explanation of `main.tf`**
- **`terraform {}`** → Specifies required providers and versions.
- **`provider "aws" {}`** → Defines AWS region and credentials.
- **`resource "aws_security_group" "ec2_security_group" {}`** → Creates a security group with SSH, HTTP, and HTTPS access.
- **`ingress {}`** → Defines inbound rules for SSH (22), HTTP (80), and HTTPS (443).
- **`egress {}`** → Allows all outbound traffic.

---

## ** Running Terraform Commands**
- **Initialize Terraform:**
  ```sh
  terraform init
  ```
- **Validate Configuration:**
  ```sh
  terraform validate
  ```
- **Preview Deployment:**
  ```sh
  terraform plan
  ```
- **Deploy Resources:**
  ```sh
  terraform apply
  ```
  Type `yes` when prompted.
- **Get EC2 Public IP:**
  ```sh
  terraform output ec2_public_ip
  ```
- **Destroy Infrastructure:**
  ```sh
  terraform destroy
  ```
  Type `yes` when prompted.

---

## ** Conclusion**
This guide covered:
- Installing Terraform on macOS
- Configuring AWS credentials
- Writing a Terraform script to deploy an EC2 instance
- Attaching custom IAM policies manually
- Running Terraform commands for deployment and cleanup

**Happy Terraforming!**

