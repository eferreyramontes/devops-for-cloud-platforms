resource "aws_ecr_repository" "ecr" {
  name = "romans"
}

resource "aws_iam_user" "deploy" {
  name = "deployer"
}

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.ecr.name
  policy     = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep image deployed with tag 'master''",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["master"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 2 any images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 2
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "deploy" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid : "VisualEditor0",
        Effect : "Allow",
        Action : "ecr:PutImage",
        Resource : aws_ecr_repository.ecr.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "deploy" {
  policy_arn = aws_iam_policy.deploy.arn
  user       = aws_iam_user.deploy.id
}