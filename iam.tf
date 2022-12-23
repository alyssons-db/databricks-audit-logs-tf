resource "aws_iam_role" "logdelivery" {
  name               = "${var.prefix}-logdelivery"
  description        = "(${var.prefix}) UsageDelivery role"
  assume_role_policy = data.databricks_aws_assume_role_policy.logdelivery.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.prefix}-instanceprofile"
  role = aws_iam_role.s3access.name
}

resource "aws_iam_policy" "this" {
  name        = "${var.prefix}-s3accesspolicy"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = [
          "s3:ListBucket",
        ],
        Effect    = "Allow"
        Resource  = [
            "${aws_s3_bucket.logdelivery.arn}"
        ]
      },
      {
        Action    = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
        ],
        Effect    = "Allow"
        Resource  = [
            "${aws_s3_bucket.logdelivery.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "s3access" {
  name = "${var.prefix}-s3accessrole"
  path = "/"

  assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                  "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
    EOF
}

data "aws_iam_policy_document" "pass_role_for_s3_access" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.s3access.arn]
  }
}

resource "aws_iam_policy" "pass_role_for_s3_access" {
  name   = "pass-role-for-s3-access"
  path   = "/"
  policy = data.aws_iam_policy_document.pass_role_for_s3_access.json
}

resource "aws_iam_role_policy_attachment" "cross_account" {
  policy_arn = aws_iam_policy.pass_role_for_s3_access.arn
  role       = var.crossaccount_role_name
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.s3access.name
  policy_arn = aws_iam_policy.this.arn
}

resource "databricks_instance_profile" "this" {
  provider = databricks.wsp
  instance_profile_arn = aws_iam_instance_profile.this.arn
}