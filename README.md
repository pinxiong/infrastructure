## Infrastructure

The purpose of this project is to help you build your infrastructure in your [aws account](https://aws.amazon.com/).

## Prerequisites

+ Create an [aws account](https://aws.amazon.com/) with the IAM `AdministratorAccess` permission
+ Install and configure [aws CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
+ Install and configure [terraform](https://www.terraform.io/downloads)

## How to work

There are two steps to help you create your infrastructure as follows:

### Setup environment

Terraform saves all changes in `*.tfstate` file, so we'd better store `*.tfstate` in `aws s3 bucket` instead of local machine. This step will build a `aws s3 bucket` to store `*.tfstate` file.

+ Init Terraform

```shell
$ cd setup
$ terraform init
```

+ Create s3 bucket
```shell
$ terraform apply
```

You will be prompted to enter an `aws region code`, such as `us-east-1`. After that, you need to make sure the listed resources that will be crated and then enter `yes`

You can see the output `s3_bucket_terraform_state` below
```shell
Outputs:

s3_bucket_terraform_state = "**********-us-east-1"
```

### Build resources

Now, we begin to build the resources including VPC, subnets, EKS, Jump server etc.

+ Setup remote backup
```shell
$ cd ../region/virginia 
```
and then, update the block of `s3` in `providers.tf` file
```terraform
backend "s3" {
    bucket  = "default-terraform-state-us-east-1"
    key     = "terraform/backend.tfstate"
    region  = "us-east-1"
    encrypt = "true"
  }
```

The following things maybe need to be modified:
1. Set `bucket` as the output of `s3_bucket_terraform_state`
2. Set `key` as the path to store `*.tfstate` file in s3 bucket
3. Update `region` as the region code that you entered when creating s3 bucket above
4. Set `encrypt` as `true`

+ Create resources

You can modify the configuration in the `main.tf` file according to your needs, and then run the following commands
```shell
$ terraform init
$ terraform apply
```

You will be prompted to enter `yes` after confirmed the listed resources.