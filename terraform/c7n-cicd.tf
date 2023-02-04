resource "aws_codebuild_project" "c7n_codebuild_demo" {
  badge_enabled  = false
  build_timeout  = 60
  name           = "7n-codebuild-demo"
  queued_timeout = 480
  service_role   = aws_iam_role.custodian_codebuild_role.arn

  artifacts {
    type                   = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0" # ubuntu 20.04
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"

    environment_variable {
      name  = "account_id"
      value = data.aws_caller_identity.current.account_id
    }
  }

  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    type                = "CODEPIPELINE"
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "tf-c7n-pipeline"
  role_arn = aws_iam_role.custodian_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.c7n_cicd_asset_bkt.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github-c7n-demo.arn
        FullRepositoryId = "chen188/c7n-demo"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
    #   output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = "7n-codebuild-demo"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "github-c7n-demo" {
  name          = "github-c7n-demo-connection"
  provider_type = "GitHub"
}