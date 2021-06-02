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

        stage('Pull Source Code') {
            steps {
               script {
                   // Clean Workspace before start
                   cleanWs()

                   // Get code from GitHub repository
                   git(
                    url: 'https://github.com/abelasuvalenteen/terraform-oci.git',
                    branch: 'master'
                    )
               }
            }
        }

        stage('Application') {
            steps {
               script {
                 if("${params.buildType}".equalsIgnoreCase("build")) {
                   echo "Building : Compartment & VCN"
                   bat """
                       cd ${WORKSPACE}\\application\\compartment
                       terraform init
                       terraform plan
                       terraform apply -auto-approve
                   """
                   echo "Building : Compute and Load Balancer"
                   bat """
                       cd ${WORKSPACE}\\application\\compute
                       terraform init
                       terraform plan
                       terraform apply -auto-approve
                   """
                  } else {
                   echo "Running Destroy"
                   bat """
                      cd ${WORKSPACE}\\application\\compartment
                      terraform destroy -auto-approve
                   """
                  bat """
                      cd ${WORKSPACE}\\application\\compute
                      terraform destroy -auto-approve
                  """
                  }
               }
            }
        }

        stage('Bastion') {
            steps {
               script {
                  if("${params.buildType}".equalsIgnoreCase("build")) {
                     echo "Building : Compartment"
                     bat """
                         cd ${WORKSPACE}\\bastion\\compartment
                         terraform init
                         terraform plan
                         terraform apply -auto-approve
                     """
                     echo "Building : VCN"
                     bat """
                         cd ${WORKSPACE}\\bastion\\vcn
                         terraform init
                         terraform plan
                         terraform apply -auto-approve
                     """
                      echo "Building : Computeinstance"
                      bat """
                          cd ${WORKSPACE}\\bastion\\computeinstance
                          terraform init
                          terraform plan
                          terraform apply -auto-approve
                      """
                    } else {
                     echo "Running Destroy"
                     bat """
                        cd ${WORKSPACE}\\bastion\\compartment
                        terraform destroy -auto-approve
                        cd ${WORKSPACE}\\bastion\\vcn
                        terraform destroy -auto-approve
                        cd ${WORKSPACE}\\bastion\\computeinstance
                        terraform destroy -auto-approve
                    """
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
