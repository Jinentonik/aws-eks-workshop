locals {
  remote_node_cidr = var.remote_network_cidr
  remote_pod_cidr  = var.remote_pod_cidr
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                             = var.cluster_name
  kubernetes_version                          = var.cluster_version
  endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  upgrade_policy = {
    support_type = "STANDARD"
  }
  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        nodeAgent = {
          enablePolicyEventLogs = "true"
        }
        enableNetworkPolicy = "true"
      })
    }
    kube-proxy = {
      before_compute = true
      most_recent    = true
    }
    coredns = {
      before_compute = true
      most_recent    = true
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_node_security_group    = false
  security_group_additional_rules = {
    hybrid-node = {
      cidr_blocks = [local.remote_node_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }

    hybrid-pod = {
      cidr_blocks = [local.remote_pod_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }

  node_security_group_additional_rules = {
    hybrid_node_rule = {
      cidr_blocks = [local.remote_node_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }

    hybrid_pod_rule = {
      cidr_blocks = [local.remote_pod_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }


  remote_network_config = {
    remote_node_networks = {
      cidrs = [local.remote_node_cidr]
    }
    # Required if running webhooks on Hybrid nodes
    remote_pod_networks = {
      cidrs = [local.remote_pod_cidr]
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types           = ["t3.medium"]
      force_update_version     = true
      release_version          = var.ami_release_version
      use_name_prefix          = false
      iam_role_name            = "${var.cluster_name}-ng-default"
      iam_role_use_name_prefix = false

      min_size     = 3
      max_size     = 6
      desired_size = 3

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        workshop-default = "yes"
      }

      metadata_options = {
        http_put_response_hop_limit = 2
      }
    }
  }

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace = "kube-system"
  # upgrade_install = true
  set = [
    {
      name  = "clusterName"
      value = "eks-workshop-1"
    },
    {
      name  = "serviceAccount.name"
      value = "kube-system-service-account"
    },
    {
      name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.aws_load_balancer_controller.arn
    }
  ]
}

resource "helm_release" "kagent_crds" {
  name       = "kagent-crds"
  chart     = "oci://ghcr.io/kagent-dev/kagent/helm/kagent"
  namespace = "kagent"
  create_namespace = true
  
  # upgrade_install = true
  set = [
    {
      name  = "providers.default"
      value = "openAI"
    },
    {
      name  = "providers.openAI.apiKey"
      value = var.openAI_API_KEY
    }
  ]
}

resource "helm_release" "kagent" {
  name       = "kagent"
  chart     = "oci://ghcr.io/kagent-dev/kagent/helm/kagent"
  namespace = "kagent"
  # upgrade_install = true
  set = [
    {
      name  = "providers.default"
      value = "openAI"
    },
    {
      name  = "providers.openAI.apiKey"
      value = var.openAI_API_KEY
    }
  ]
}
