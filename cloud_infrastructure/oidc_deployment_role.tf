data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

locals {
  certs_list_length = length(data.tls_certificate.github.certificates) > 5 ? 5 : length(data.tls_certificate.github.certificates)
}

output "cert_thumb_prints" {
  value = [for i in range(0, local.certs_list_length) : data.tls_certificate.github.certificates[i].sha1_fingerprint]
}

### OpenID Connect Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [for i in range(0, local.certs_list_length) : data.tls_certificate.github.certificates[i].sha1_fingerprint]
}

### Policy to establish trust relationship between aws and github
data "aws_iam_policy_document" "aws-github-trust-relationship" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:akhilakailam123/*"]
    }
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
  }
}

### Role & policy used for deployment
resource "aws_iam_role" "deployment_role" {
  name               = "aws-deployment-role"
  assume_role_policy = data.aws_iam_policy_document.aws-github-trust-relationship.json # Allows Github workflow to assume role
}

resource "aws_iam_role_policy_attachment" "deployment_role_policy_attachment" {
  # checkov:skip=CKV_AWS_274: The role requires administrator access to create and delete resources
  role       = aws_iam_role.deployment_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}