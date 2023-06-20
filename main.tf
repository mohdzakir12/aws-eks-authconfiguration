terraform {
  backend "s3" {
    # Backend configuration
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_eks_cluster" "example" {
  name = "cluster-za"
}

data "aws_eks_cluster_auth" "clutertoken" {
  name = "cluster-za"
}

data "aws_eks_node_group" "ng_info" {
  cluster_name     = data.aws_eks_cluster.example.name
  node_group_name  = data.aws_eks_cluster.example.node_groups[0].name
}

locals {
  node_group_name = data.aws_eks_node_group.ng_info.node_group_name
}

locals {
  oidcval = trimprefix(data.aws_eks_cluster.example.identity[0].oidc[0].issuer, "https://oidc.eks.us-east-1.amazonaws.com/id/")
  awsacc  = "657907747545"
  region  = "us-east-1"

  aws_auth_cm_role = [
    {
      rolearn  = data.aws_eks_cluster.example.role_arn
      username = "papu"
      groups   = ["system:masters"]
    },
    {
      groups    = ["system:bootstrappers", "system:nodes"]
      rolearn   = data.aws_eks_node_group.ng_info.node_role_arn
      username  = "system:node:{{EC2PrivateDNSName}}"
    }
  ]

  aws_auth_cm_users = [
    {
      userarn  = "arn:aws:iam::657907747545:user/m.zakir"
      username = "m.zakir"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::657907747545:user/ma.rajak"
      username = "ma.rajak"
      groups   = ["system:masters"]
    }
  ]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.clutertoken.token
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(local.aws_auth_cm_role)
    mapUsers = yamlencode(local.aws_auth_cm_users)
  }

  force = true
}

data "kubernetes_config_map_v1" "outdata" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

output "something" {
  value = data.kubernetes_config_map_v1.outdata.data
}

output "thatoutput" {
  value     = data.aws_eks_cluster_auth.clutertoken.token
  sensitive = true
}
