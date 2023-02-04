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
    # "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    # "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess",
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole",
    aws_iam_policy.custodian_lambda_exec_policy.arn
  ]

  tags = {
    tag-key = "tag-value"
  }
}
data "aws_caller_identity" "current" {}
data "aws_iam_policy_document" "custodian_lambda_exec_policy" {
  statement {
    # add more permissions required by your own policies
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
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:DeleteLoadBalancer"
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

resource "aws_iam_policy" "custodian_lambda_exec_policy" {
  name        = "custodian-lambda-exec"
  description = "used by custodian lambda"

  policy = data.aws_iam_policy_document.custodian_lambda_exec_policy.json
}

############## custodian_allowlist_test_role ###############
resource "aws_iam_role" "custodian_allowlist_test_role" {
  name = "custodian-allowlist-test-role"

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
          "Service": [
            "lambda.amazonaws.com",
          ]
        }
      },
    ]
  })

  managed_policy_arns = [
    # "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    # aws_iam_policy.custodian_cicd_policy.arn
  ]

  tags = {
    tag-key = "tag-value"
  }
}

# data "aws_iam_policy_document" "custodian_cicd_policy" {
#   statement {
#     actions = [
#       "cloudwatch:PutMetricData",
#       "ec2:DescribeNetworkInterfaces",
#       "ec2:DeleteNetworkInterface",
#       "ec2:CreateNetworkInterface",
#       "events:PutRule",
#       "events:PutTargets",
#       "iam:PassRole",
#       "lambda:CreateFunction",
#       "lambda:TagResource",
#       "lambda:CreateEventSourceMapping",
#       "lambda:UntagResource",
#       "lambda:PutFunctionConcurrency",
#       "lambda:DeleteFunction",
#       "lambda:UpdateEventSourceMapping",
#       "lambda:InvokeFunction",
#       "lambda:UpdateFunctionConfiguration",
#       "lambda:UpdateAlias",
#       "lambda:UpdateFunctionCode",
#       "lambda:AddPermission",
#       "lambda:DeleteAlias",
#       "lambda:DeleteFunctionConcurrency",
#       "lambda:DeleteEventSourceMapping",
#       "lambda:RemovePermission",
#       "lambda:CreateAlias",
#       "logs:CreateLogStream",
#       "logs:PutLogEvents",
#       "logs:CreateLogGroup"
#     ]
#     effect    = "Allow"
#     resources = ["*"]
#   }

#   statement {
#     actions = [
#       "s3:GetObject",
#       "s3:GetObjectVersion",
#       "s3:GetBucketVersioning",
#       "s3:PutObjectAcl",
#       "s3:PutObject"
#     ]
#     effect    = "Allow"
#     resources = [
#       "${aws_s3_bucket.c7n_cicd_asset_bkt.arn}",
#       "${aws_s3_bucket.c7n_cicd_asset_bkt.arn}/*"
#     ]
#   }

#   statement {
#     actions = [
#       "codestar-connections:UseConnection"
#     ]
#     effect = "Allow"
#     resources = [
#       aws_codestarconnections_connection.github-c7n-demo.arn
#     ]
#   }

#   statement {
#     actions = [
#       "codebuild:BatchGetBuilds",
#       "codebuild:StartBuild"
#     ]
#     effect = "Allow"
#     resources = ["*"]
#   } 
# }

# resource "aws_iam_policy" "custodian_cicd_policy" {
#   name        = "custodian-cicd"
#   description = "used in custodian CI/CD env"

#   policy = data.aws_iam_policy_document.custodian_cicd_policy.json
# }



########################################
# allow codepipeline to access s3(custodian source code asset) and invoke codebuild
resource "aws_iam_role" "custodian_codepipeline_role" {
  name = "custodian-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "TrustCodePipelineService"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.custodian_codepipeline_policy.arn
  ]
}

resource "aws_iam_policy" "custodian_codepipeline_policy" {
  name  = "Codepipeline-Role-Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.c7n_cicd_asset_bkt.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.c7n_cicd_asset_bkt.bucket}/*"
        ]
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
        ]
        Effect = "Allow"
        Resource = [
          aws_codebuild_project.c7n_codebuild_demo.arn
        ]
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ]
        Effect = "Allow"
        Resource = [
          aws_codestarconnections_connection.github-c7n-demo.arn
        ]
      }
    ]
  })
}


########################################
# allow codebuild to access s3(custodian source code asset) and put build log to cloudwatch
resource "aws_iam_role" "custodian_codebuild_role" {
  name = "custodian-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "TrustCodeBuildService"
        Principal = {
          Service = "codebuild.amazonaws.com",
        }
      },{
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "TrustSelf"
        Principal = {
          AWS = "*"
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalArn": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/custodian-codebuild-role"
          }
        }
      },
    ]
  })

  managed_policy_arns = [
    # Provides read-only access to AWS services and resources.
    "arn:aws:iam::aws:policy/ReadOnlyAccess", 
    "arn:aws:iam::aws:policy/service-role/AWSConfigRulesExecutionRole",

    aws_iam_policy.custodian_lambda_exec_policy.arn,
    aws_iam_policy.custodian_codebuild_s3_cw_policy.arn,
    aws_iam_policy.custodian_policy_deployment_policy.arn
  ]
}

resource "aws_iam_policy" "custodian_codebuild_s3_cw_policy" {
  name  = "AllowCodeBuildAccessS3AndCloudwatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.c7n_cicd_asset_bkt.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.c7n_cicd_asset_bkt.bucket}/*"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/codebuild/*"
        ]
      },
      # {
      #   Action = [
      #     "sts:AssumeRole"
      #   ]
      #   Effect = "Allow"
      #   Resource = [
      #     aws_iam_role.custodian_policy_deployment_role.arn
      #   ]
      # }
    ]
  })
}

resource "aws_iam_policy" "custodian_policy_deployment_policy" {
  name  = "AllowCustodianManageLambdaAndConfig"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Action = [
          "lambda:GetFunction",
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:UpdateFunctionCode",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:GetPolicy",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:UpdateEventSourceMapping",
          "lambda:DeleteEventSourceMapping",
          "lambda:PutFunctionConcurrency",
          "lambda:DeleteFunctionConcurrency",
          "lambda:CreateAlias",
          "lambda:UpdateAlias",
          "lambda:DeleteAlias"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:lambda:*:*:function:custodian-*"
        ]
      },
      {
        Action = [
          "lambda:CreateEventSourceMapping",
          "elasticloadbalancing:Describe*",
          "iam:ListRoles",
          "iam:GetRole",
          "ec2:Describe*"
        ]
        Effect = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "events:DescribeRule",
          "events:PutRule",
          "events:DeleteRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:EnableRule",
          "events:TagResource",
          "events:ListTargetsByRule"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:events:*:*:rule/custodian-*"
        ]
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:CreateNetworkInterface"
        ]
        Effect = "Allow"
        Resource = ["*"]
      },
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Resource = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/custodian-codebuild-role"]
      },
      {
        Action = [
          "iam:PassRole"
        ]
        Effect = "Allow"
        Resource = aws_iam_role.custodian_lambda_exec_role.arn
      }
    ]
  })
}
