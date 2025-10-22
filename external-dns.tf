resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace = "external-dns"
  create_namespace = true
  # upgrade_install = true
  set = [
    {
      name  = "provider.name"
      value = "aws"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-dns-sa"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_dns.arn
    },
    {
      name = "txtOwnerId"
      value = "eks-workshop-1"
    },
    {
      name = "extraArgs[0]"
      value = "--aws-zone-type=private"
    },
    {
      name = "extraArgs[1]"
      value = "--domain-filter=retailstore.com"
    }
  ]
  depends_on = [aws_iam_role_policy_attachment.external_dns]
}