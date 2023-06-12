 terraform{
  backend s3{
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

# data "aws_eks_node_group" "ng_arn_info" {
#   cluster_name    = "nextcluster"
#   node_group_name = "group_name-2023020808100816620000000d"
# }

locals {
  oidcval = trimprefix(data.aws_eks_cluster.example.identity[0].oidc[0].issuer,"https://oidc.eks.us-east-1.amazonaws.com/id/")
  awsacc = "657907747545"
  region = "us-east-1"
  # aws_auth_configmap_data = {
  #   mapRoles = {
  #     rolearn  = data.aws_eks_cluster.example.role_arn
  #     username = "papu"
  #     groups   = ["system:masters"]    
  #   }

  #   mapUsers    = [
  #       {
  #           userarn  = "arn:aws:iam::657907747545:user/shahbaz"
  #           username = "shahbaz"
  #           groups   = ["system:masters"]
  #       },
  #       {
  #           userarn  = "arn:aws:iam::657907747545:user/m.zakir"
  #           username = "m.zakir"
  #           groups   = ["system:masters"]
  #       },
  #       {
  #           userarn  = "arn:aws:iam::657907747545:user/ma.rajak"
  #           username = "ma.rajak"
  #           groups   = ["system:masters"]
  #       }
  #   ]

  #   # mapAccounts = yamlencode(var.aws_auth_accounts)
  # }
  aws_auth_cm_role = [
                {
                  rolearn  = data.aws_eks_cluster.example.role_arn
                  username = "papu"
                  groups   = ["system:masters"]    
                },
                {
                  groups = ["system:bootstrappers","system:nodes"]
                  rolearn  = data.aws_eks_node_group.ng_arn_info.node_role_arn #"arn:aws:iam::657907747545:role/group_name-eks-node-group-20230213114651389300000001" #data.aws_eks_node_group.ng_arn_info.node_role_arn #"arn:aws:iam::657907747545:role/group_name-eks-node-group-20230203121647838400000001"  #"arn:aws:iam::657907747545:role/group_name-eks-node-group"
                  username = "system:node:{{EC2PrivateDNSName}}"
                }
                # data.kubernetes_config_map_v1.outdata.data.mapRoles
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
######## it is using api version in the cluster
################################################
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.example.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     command     = "aws"
#     # This requires the awscli to be installed locally where Terraform is executed
#     args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.example.id]
#   }
# }
###############################################

provider "kubernetes" {
  host                   = data.aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.clutertoken.token
}

# resource "kubernetes_config_map_v1" "aws_auth" {
  
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     "mapRoles"    = yamlencode(local.aws_auth_cm_role)
#     "mapUsers"    = yamlencode(local.aws_auth_cm_users)
# #     "mapAccounts" = yamlencode(var.map_accounts)
#   }
# #    data = yamlencode(local.aws_auth_configmap_data)
# }

resource "kubernetes_config_map_v1_data" "aws_auth" {
  
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = yamlencode(local.aws_auth_cm_role)
    mapUsers    = yamlencode(local.aws_auth_cm_users)
  #     "mapAccounts" = yamlencode(var.map_accounts)
  }
  force = true
  #    data = yamlencode(local.aws_auth_configmap_data)
}

data "kubernetes_config_map_v1" "outdata" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }
}

output "something" {
  value = data.kubernetes_config_map_v1.outdata.data
}

output "thatoutput" {
  value = data.aws_eks_cluster_auth.clutertoken.token
  sensitive = true
}