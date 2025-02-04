##
# ArgoCD admin password hash
#
# This is a hash of the password, generated using:
#
# ```bash
# htpasswd -nbBC 10 "" $PASSWORD | tr -d ':\n' | sed 's/$2y/$2a/'
# ```
#
# This sample hash is for the password "example".
#
# DO NOT USE THIS PASSWORD IN PRODUCTION!
##
argocd_admin_password_hash = "$2a$10$4SV.QVw1GFskfY62SJbfjuucDVyLXNntHlS3pbKuQ29Jt0roX8sUS"

# repository_credentials = {
#   "github-example" = {
#     url      = "https://github.com/example"
#     username = "not-used"
#     password = "ghp_asdfasdf"
#   }
# }

# applications = {
#   "example-argo-private-app" = {
#     project = "default"
#     source = {
#       repoURL = "https://github.com/example/argo-private-app.git"
#       path    = "./"
#     }
#     destination = {
#       server    = "https://kubernetes.default.svc"
#       namespace = "default"
#     }
#     syncPolicy = {
#       automated = {
#         prune    = true
#         selfHeal = true
#       }
#     }
#   }
# }
