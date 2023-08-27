## Infrastructure

The purpose of this project is to help you build your infrastructure in your [aws account](https://aws.amazon.com/).

## Prerequisites

+ Create an [aws account](https://aws.amazon.com/) with the IAM `AdministratorAccess` permission
+ Install and configure [aws CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
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
    bucket  = "**********-us-east-1"
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

## How to verify

Now, all the resources have been built, The next step is to how to verify them.

We can use `Jump Server` to test if they work well. We just need to verify EKS because it depends on VPC and subnets.

+ Login Jump Server

We can use `Session Manager` to login `Jump Server`, and then setups the environment
```shell
$ sudo -s
```
+ Configure Access Key and Secret Access Key

**NOTE**: You **MUST** use the Access Key and Secret Access Key of user that created EKS

```shell
$ aws configure
AWS Access Key ID [*******************]: 
AWS Secret Access Key [*********************]: 
Default region name [us-east-1]: 
Default output format [json]
```

You can check it

```shell
$ aws sts get-caller-identity
{
    "Account": "***********",
    "UserId": "**********************",
    "Arn": "arn:aws:iam::***********:user/****"
}
```

+ Update or create kubeconfig

```shell
$ aws eks --region region-code update-kubeconfig --name cluster_name
```
`region-code` is aws region code, such as `us-east-1`

`cluster-name` is the name of the created EKS

+ Access EKS cluster

```shell
$ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   172.20.0.1   <none>        443/TCP   2d2h
```