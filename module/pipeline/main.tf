############################################################################################
##========================Define S3 bucket related resources==============================##
############################################################################################
resource "aws_s3_bucket" "archive" {
  bucket = local.bucket_name
  tags   = merge(local.pipeline_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "archive" {
  bucket = aws_s3_bucket.archive.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "archive" {
  bucket = aws_s3_bucket.archive.id
  acl    = "private"
}

resource "aws_iam_policy" "s3_archive" {
  name   = "${local.bucket_name}-s3-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          aws_s3_bucket.archive.arn,
          "${aws_s3_bucket.archive.arn}/*"
        ]
      }
    ]
  })
}

############################################################################################
##============================Define ECR related resources================================##
############################################################################################
resource "aws_ecr_repository" "ecr" {
  name                 = local.project_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  tags = merge({
    Name : local.project_name
  }, local.pipeline_tags)
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr.name
  policy     = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "AllowPushPull",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${local.account_id}:root"
          ]
        },
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  )
}

############################################################################################
##========================Define code pipeline related resources==========================##
############################################################################################
resource "aws_iam_role" "pipeline" {
  name               = "${local.pipeline_name}-pipeline-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "codebuild.amazonaws.com",
            "codedeploy.amazonaws.com",
            "codepipeline.amazonaws.com",
            "ec2.amazonaws.com",
            "ecs.amazonaws.com",
            "ecs-tasks.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "build__s3-archive" {
  policy_arn = aws_iam_policy.s3_archive.arn
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__AWSCodeCommitFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__AWSCodeBuildAdminAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__AWSCodePipelineFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__CloudWatchFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__AmazonECS_FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.pipeline.name
}

resource "aws_iam_role_policy_attachment" "build__EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.pipeline.name
}

resource "aws_cloudwatch_log_group" "pipeline" {
  name              = "/aws/pipeline/${local.pipeline_name}/"
  retention_in_days = 1
  tags              = merge({
    Name : local.pipeline_name
  }, local.pipeline_tags)
}

# Create repository
resource "aws_codecommit_repository" "repository" {
  repository_name = local.repository_name
  default_branch  = "master"
  description     = "This is the simple golang web application repository."
  tags            = merge(local.pipeline_tags, {
    Name = "${local.repository_name}-repository"
  })
}

# Create codebuild
resource "aws_codebuild_project" "build" {
  name           = local.build_name
  badge_enabled  = false
  build_timeout  = 60
  queued_timeout = 480
  service_role   = aws_iam_role.pipeline.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    type     = "S3"
    location = aws_s3_bucket.archive.bucket
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }
  source {
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.pipeline.name
      stream_name = local.build_name
    }
  }
  tags = merge({
    Name : local.build_name
  }, local.pipeline_tags)
}

# Create codepipeline
resource "aws_codepipeline" "codepipeline" {
  name     = local.pipeline_name
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.archive.bucket
    type     = "S3"
  }

  stage {
    name = "${local.project_name}-source"
    action {
      name             = "${local.project_name}-source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      run_order        = 1
      version          = "1"
      output_artifacts = ["source_op"]
      configuration    = {
        RepositoryName       = aws_codecommit_repository.repository.repository_name
        BranchName           = aws_codecommit_repository.repository.default_branch
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "${local.project_name}-build"
    action {
      name             = "${local.project_name}-build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_op"]
      output_artifacts = ["build_op"]
      version          = "1"
      run_order        = 1

      configuration = {
        ProjectName          = aws_codebuild_project.build.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "AWS_DEFAULT_REGION"
              type  = "PLAINTEXT"
              value = local.region
            },
            {
              name  = "AWS_ACCOUNT_ID"
              type  = "PLAINTEXT"
              value = local.account_id
            },
            {
              name  = "IMAGE_REPO_NAME"
              type  = "PLAINTEXT"
              value = local.image_name
            },
            {
              name  = "IMAGE_TAG"
              type  = "PLAINTEXT"
              value = "latest"
            },
            {
              name  = "CONTAINER_NAME"
              type  = "PLAINTEXT"
              value = local.project_name
            }
          ]
        )
      }
    }
  }

  stage {

    name = "${local.project_name}-deploy"
    action {
      name            = "${local.project_name}-deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_op"]
      run_order       = 1
      version         = "1"

      configuration = {
        ClusterName = local.ecs_cluster_name
        ServiceName = local.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
