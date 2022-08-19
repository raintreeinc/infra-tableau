[![tfsec](https://github.com/raintreeinc/infra-tableau/actions/workflows/terraform_tfsec.yml/badge.svg)](https://github.com/raintreeinc/infra-tableau/actions/workflows/terraform_tfsec.yml)

# Code pipeline to deploy Tableau infrastructure
This pipeline deploys Tableau Server 2022.1.4 to a RHEL 8 server in AWS

## Workflow overview
- .github/workflows/cft_deploy.yml - (obsolete)
- .github/workflows/terraform_tfsec.yml - Runs Terraform tfsec code analysis, scans for vulnerabilities, and posts results as an artifact. Note, these are not blocking tests, so deployments can proceed even with failing tfsec results.
- .github/workflows/terraform_plan.yml - Pulls secrets information from the appropriate environment and then builds the infrastructure accordingly. Valid environments are DEV, SQA, UAT, and PRD.
- .github/workflows/terraform_apply.yml - Downloads plan artifact from the terraform_plan step and then applies the infrastructure changes. 

## Steps to change infrastructure
1. Clone repo to your local system.
2. Create a local branch in the repository.
3. Edit the Terraform files as needed (see below for overview of what is stored in each file).
4. Commit changes and publish new branch to the remote.
5. From GitHub, trigger a PR to merge the changes - this will trigger the tfsec analysis and create the Terraform plan file.
7. Browse to "Actions" and review the screen spew for the Terraform plan steps to confirm you are satisfied with the changes to be performed.
8. Squash and merge the changes which will both delete the current working branch and apply the Terraform plan artifact.
9. Delete the local branch from your system and perform a git pull in "main" to update your local repo with the changes.

## Infrastructure overview
- alb.tf: Creates two ALB (one for access to TSM one for access to Tableau management interface) and associated listeners. Traffic over insecure channels are redirected to SSL-encrypted channels. 
- asg.tf: Creates autoscaling group that will deploy EC2 instance(s).
- backend.tf: Stub backend defintion that defines the backend is stored in S3. All details on backend are stored in secrets management. 
- cloudwatch.tf: Creates cloudwatch log group for use by Tableau.
- data.tf: All data references used in code. Queries existing infrastructure to avoid using static defintions wherever possible. 
- efs.tf (disabled): Creates EFS volume to use as external datastore for workbook revisions and extracts. It requires an advanced license to leverage this feature. 
- iam.tf: Creates IAM role and instance profile for the Tableau server and associated infrastructure. 
- lt.tf: Creates RHEL8 launch template based on the latest published AMI. This means that if this pipeline is executed a month after creation, it will likely detect changes and create a plan that will update the launch template to use the latest AMI. 
- main.tf: Pulls region info from vars but largely there for completion-sake. 
- providers.tf: Sets minimum version of Terraform modules to be used by the pipeline during infrastructure creation
- r53.tf: Creates Route 53 entries for the Tableau server web interface and Tableau TSM interface. 
- rds.tf: Creates a Tableau subnet group, Aurora cluster, and cluster instances. 
- s3.tf: Creates both a logging bucket and an extracts bucket. 
- secrets.tf: Any secrets referenced within the AWS infrastrucutre are housed in AWS secrets manager so they can be referenced by the pipeline, however they are pulled from an associated GitHub secret unless dynamically generated at runtime. 
- tg.tf: Creates the listener target groups for both the Tableau and TSM interface.
- variables.tf: Overview of the variables leveraged by Terraform. The values themselves however are stored within GitHub secrets either at the repository level or the region level. 

## Creating / Destroying infrastructure
To create or modify infrastructure, leave the value in the terraform_plan.yml file for create set to "true." If this value is set to "false," all infrastructure will be terminated/deleted. 