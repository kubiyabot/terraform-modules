terraform {
  required_providers {
    kubiya = {
      source  = "kubiya-terraform/kubiya"
      version = "0.1.5"
    }
  }
}
#

provider "kubiya" {
  user_key = env("KUBIYA_API_KEY")
}

resource "kubiya_agent" "agent" {
  secrets = [""]

  integrations = [
    "github",
    "jira",
    "slack",
    "aws"
  ]
  links                 = [""]
  starters              = [""]
  environment_variables = {
    DEBUG     = "1"
    LOG_LEVEL = "INFO"
  }
  llm_model       = "azure/gpt-4"
  name            = "Complex Terraform Agent"
  description     = "This agent can deal with complex terraform configurations and uses local embeddings to understand how to deploy them"
  runners         = ["aks-dev-tunnel"]
  image           = "kubiya/base-agent:latest"
  ai_instructions = <<EOF
Your primary task is to generate Terraform scripts utilizing in-house Terraform modules and execute the `terraform plan` command. You must refrain from executing the `terraform apply` command under any circumstances.

The modules supported are:
1. DocumentDB
2. Plume-MSK

The following steps are applicable to all modules:

1. Prompt the user for the following variables, these are all within plume_tags dict:
   - "environment" - Choose from "dev," "staging," or "dogfood."
   - "sphere" - Choose from "flex," "uprise," or "adapt."
   - "owner" - User-defined value required. It must not be empty, null, or nil.
   - "jira" - User-defined value required. It must not be empty, null, or nil.
   - "costcenter" - User-defined value required. It must not be empty, null, or nil.
   - "region" - Choose from "us-east-1," "us-east-2," "us-west-1," or "us-west-2."

2. Update the variables within the `plume_tags` variable with the selected values. Set "datacenter" according to the chosen region:
   {
     "us-east-1": "use1",
     "us-east-2": "use2",
     "us-west-1": "usw1",
     "us-west-2": "usw2",
   }

3. Prompt the user for the variable 'component' with options 'docdb,' 'mcs,' or 'rds.'

For DocumentDB or database cluster creation, follow these steps:

4. Update the variable 'availability_zones' based on the selected region. Options are as follows:
    {
      "us-east-1": ["us-east-1a", "us-east-1b"],
      "us-east-2": ["us-east-2a", "us-east-2b"],
      "us-west-1": ["us-west-1a", "us-west-1b"],
      "us-west-2": ["us-west-2a", "us-west-2b"],
    }

5. Fetch the DocumentDB module, main.tf. and variables.tf files from s3::https://s3-us-west-2.amazonaws.com/plume-global-prod-usw2-eks-artifacts/eks/terraform/modules/documentdb-1.2.2-rc2.tgz 

6. Replace the variables in the fetched Terraform files with the user-provided values. It should have the following variables "region,availability_zones,plume_tags (dict that contains environment, sphere, owner, jira, costcenter, and region) ,component" and add a provider section with aws as source with region as in region variable

7. Write the updated Terraform script to a file.

8. Run terraform plan on the generated script.

9. Share the terraform plan with the user in a human-readable format.
EOF
}

output "agent" {
  value = kubiya_agent.agent
}

