agent_name = "argocd-agent-tf"
agent_runners = "aks-dev"
agent_description = "used to test argocd diff and sync tools"
agent_llm_model = "azure/gpt-4"
agent_image = "kubiya/base-agent:tools-v5"

agent_tool_sources = [
    "https://raw.githubusercontent.com/kubiyabot/terraform-modules/DEV-949-akamai-argocd-github-use-case/argocd/argocd-tools/argo-diff-tool/argo-diff-tool.yaml",
    "https://raw.githubusercontent.com/kubiyabot/terraform-modules/DEV-949-akamai-argocd-github-use-case/argocd/argocd-tools/argo-sync-tool/argo-sync-tool.yaml",
    "https://raw.githubusercontent.com/kubiyabot/terraform-modules/DEV-949-akamai-argocd-github-use-case/argocd/argocd-tools/argo-set-tool/argo-set-tool.yaml"
]
agent_integrations = ["slack"]
agent_environment_variables = {
    #DEBUG           = "1"
    LOG_LEVEL       = "INFO"
    ARGOCD_SERVER = "argocd-server.argocd"
    ARGOCD_USERNAME = "admin"
    APPROVING_USERS = ""
}

agent_ai_instructions = <<EOF
1.You are an intelligent agent able to give the diff between a live argocd app state
and a specified revision using the argocd CLI diff command and sync it when asked using the argocd CLI command.
2.you are an intelligent agent able sync  a live argocd app state and a specified revision using the argocd CLI sync command.
EOF
