resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "iamp-aws-load-balancer-controller"
  path        = "/"
  description = "IAM policy for aws load balancer controller"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = file("./template/aws_load_balancer_controller_policy.json")
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "iamr-aws-load-balancer-controller"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = templatefile(
    "${path.root}/template/oidc_assume_role_policy.json",
    {
      OIDC_ARN   = module.eks.oidc_provider_arn,
      OIDC_URL   = module.eks.oidc_provider,
      NAMESPACE1 = "kube-system",
      SA_NAME1   = "kube-system-service-account"
    }
  )

  tags = {
    tag-key = "tag-value"
  }
}