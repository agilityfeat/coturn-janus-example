# COTURN + JANUS example

1. Init Terraform state in terraform directory: `cd terraform && terraform init`
2. Set the right region on `terraform/main.tf`
3. Set vpc & subnet ids and ssh key pair name on `terraform/terraform.tfvars`
4. Apply infrastructure changes: `terraform apply`
5. Note the ip address for the new servers
6. Add ips to Ansible inventory on `ansible/inventory/hosts.ini`
7. Configure Janus server using ansible: `cd ../ansible && ansible-playbook -i inventory/hosts.ini janus.yml`
8. Configure Coturn server using janus: `ansible-playbook -i inventory/hosts.ini coturn.yml`