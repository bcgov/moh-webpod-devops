[![Lifecycle:Maturing](https://img.shields.io/badge/Lifecycle-Maturing-007EC6)](<Redirect-URL>)  
This is a template for MoH repositories. All repositories should meet the following requirements
* Check the total lines of change of pull request (PR); over the 200–400-line range (of change)
* Check for one or more lifecycle badges
* Check for a compliance file, and compliance status
* Check for a license file
* Check for ReadMe
* Check for CONTRIBUTING file
* Close issues that are stale
* Close pull requests that are stale
* Request for topic of ministry code
* Request for words matter topic
* It is highly recommended that all repositories contain a Contributors Code of Conduct file, which contains guidelines on how to collaborate on the repository

How to get running for devs (coles notes draft version by Conrad):

1. Install terraform cli
1. Install terragrunt cli
1. Install aws cli
1. Log into the [OCIO AWS sign-in page](https://login.nimbus.cloud.gov.bc.ca/api) (need to get SPOC approval and Nate Coster to give you access)

https://login.nimbus.cloud.gov.bc.ca/api

1. Find your environment. Our DEV environment is "666395672448 - ynr9ed-dev"
1. Click on "Click for Credentials"
1. Click on "Click to copy"
1. Paste the copied commands into your console to get all your environment variables (note: the AWS_SESSION_TOKEN expires after a bit, so you'll have to do this step periodically)
1. Set LICENSE_PLATE env var based on the AWS value
1. Set TF_VAR_TIMESTAMP env var to a random string (anything)
1. From the dev directory, run terragrunt commands
