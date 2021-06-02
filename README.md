OCI Terrafom Templates

Pre-requisites:
    > Install OCI Cli on workstation
    > Install Terraform
    > Subscribe for OCI Account
    
Template covers below setup
  1. 2 Compartments
  2. Bastion host
  3. Load Balancer
  4. Compute Instance

    Pre-requiste for Session Validation from Workstation:
    > Run "oci session authenticate" [Autheticate with subscription credentials in the browser launch]
    > Copy & paste the public key file after running above command to OCI > Identity > Users > API Keys > Paste Pub Key
    
    Terraform Execution Steps:
    1. Clone the repo
    2. Navigate to application folder
       > Navigate to each folder under the application and perform below actions
         1. "compartment" ; 2. "compute"
                > Define the provider.tf and tfvars
                > terraform init
                > terraform plan
                > terraform apply
    3. Navigate to bastion folder
       > Navigate to each folder under the bastion and perform below actions
         1. "compartment" ; 2. "vcn"; 3. "computeinstance"
                > Define the provider.tf and tfvars
                > terraform init
                > terraform plan
                > terraform apply
Jenkins Run:
       
        > Configure a pipeline job
        > Setup Repo details in the job > configure
        > Build with parameters