pipeline {
    agent {
      node {
        label "win_slave"
      }
    }

    parameters {
        string(defaultValue: "build", description: "Input build or destroy", name: "buildType")
    }

    options { skipDefaultCheckout() }

    stages {
        stage('OCI Session Refresh') {
            steps {
               script {
                   echo "OCI session Authenticate"
                   bat "oci session refresh --profile terraform-oci"
               }
            }
        }

        stage('Init') {
            steps {
               script {
                 if("${params.buildType}".equalsIgnoreCase("build")) {
                   echo "Terraform Init"
                   bat "terraform init"
                  } else {
                   echo "Skipping init"
                  }
               }
            }
        }

        stage('Validate & Plan') {
            steps {
               script {
                  if("${params.buildType}".equalsIgnoreCase("build")) {
                   echo "Terraform Validate"
                   bat "terraform validate"
                   echo "Terraform Plan"
                   bat "terraform plan"
                  } else {
                   echo "Skipping plan"
                  }
               }
            }
        }

        stage('Apply') {
            steps {
               script {
                  if("${params.buildType}".equalsIgnoreCase("build")) {
                   echo "Terraform Apply"
                   bat "terraform apply -auto-approve"
                  } else {
                   echo "Skipping apply"
                  }
               }
            }
        }

        stage('Destroy') {
            steps {
               script {
                  if("${params.buildType}".equalsIgnoreCase("destroy")) {
                   echo "Terraform Destroy"
                   bat "terraform destroy"
                  } else {
                   echo "Skipping destroy"
                  }
               }
            }
        }
    }

    post {
        success {
            echo "Job Success"
        }
        failure {
            echo "Job Failed"
        }
    }
}
