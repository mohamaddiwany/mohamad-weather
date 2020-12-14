A simple file that using Terraform to create instances of Amzaon AWS EC2 servers,
 running Docker with containerized Nginx daemon. 
it uses Amazon AMI PV image for eu-central-1 datacenter.
To run , not forget if you want to change any thing I made terraform.tvfars file
that you could change in it and don't forget later to copy it to variables.tf
I hope you clone and modify my code and tell me if I could update .
To check if revurses will be created:
$ terraform plan
To create EC2 instances and their dependencies:
$ terraform apply
To destroy all :
terraform destroy

Notes:
you had to make sure that you had already Docker and terraform on your computer.
