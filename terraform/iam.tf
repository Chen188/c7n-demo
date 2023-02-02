############## custodian_lambda_exec_role ###############
resource "aws_iam_role" "custodian_lambda_exec_role" {
  name = "custodian-lambda-exec-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "TrustLambdaService"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole",
    aws_iam_policy.custodian_lambda_exec.arn
  ]

  tags = {
    tag-key = "tag-value"
  }
}
data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "inline_custodian_lambda_exec_policy" {
  statement {
    actions = [
      "ec2:DeleteNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:UpdateSecurityGroupRule*",
      "ec2:ModifySecurityGroupRules",
      "ec2:ModifyInstanceAttribute",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:SetSecurityGroups",
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions = [
      "iam:ListAttachedRolePolicies",
      "iam:DetachRolePolicy",
      "iam:AttachRolePolicy"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/custodian*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "custodian_lambda_exec" {
  name        = "custodian-lambda-exec"
  description = "used by custodian lambda"

  policy = data.aws_iam_policy_document.inline_custodian_lambda_exec_policy.json
}

############## custodian_cicd_role ###############
# assumed by code pipeline, to create lambda and config rules
# when depolying c7n policies.
resource "aws_iam_role" "custodian_cicd_role" {
  name = "custodian-cicd-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "TrustLambdaService"
        Principal = {
          "Service": "codepipeline.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole",
    aws_iam_policy.custodian_cicd_permissions.arn
  ]

  tags = {
    tag-key = "tag-value"
  }
}

data "aws_iam_policy_document" "inline_custodian_cicd_permissions" {
  statement {
    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:CreateNetworkInterface",
      "events:PutRule",
      "events:PutTargets",
      "iam:PassRole",
      "lambda:CreateFunction",
      "lambda:TagResource",
      "lambda:CreateEventSourceMapping",
      "lambda:UntagResource",
      "lambda:PutFunctionConcurrency",
      "lambda:DeleteFunction",
      "lambda:UpdateEventSourceMapping",
      "lambda:InvokeFunction",
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateAlias",
      "lambda:UpdateFunctionCode",
      "lambda:AddPermission",
      "lambda:DeleteAlias",
      "lambda:DeleteFunctionConcurrency",
      "lambda:DeleteEventSourceMapping",
      "lambda:RemovePermission",
      "lambda:CreateAlias",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = [
      "${aws_s3_bucket.c7n-cicd-asset-bkt.arn}",
      "${aws_s3_bucket.c7n-cicd-asset-bkt.arn}/*"
    ]
  }

  statement {
    actions = [
      "codestar-connections:UseConnection"
    ]
    effect = "Allow"
    resources = [
      aws_codestarconnections_connection.github-c7n-demo.arn
    ]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    effect = "Allow"
    resources = ["*"]
  } 
}

resource "aws_iam_policy" "custodian_cicd_permissions" {
  name        = "custodian-cicd"
  description = "used in custodian CI/CD env"

  policy = data.aws_iam_policy_document.inline_custodian_cicd_permissions.json
}
