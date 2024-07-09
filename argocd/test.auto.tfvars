agent_name = "argo-diff-test-tf"
agent_runners = "aks-dev"
agent_description = "used to test argocd diff tool"
agent_llm_model = "azure/gpt-4"
agent_image = "kubiya/base-agent:tools-v4"

agent_tool_sources = [
    "https://gist.githubusercontent.com/EvgeniyReich/24865746c00a1eaf1a87044465f0ecf1/raw/918a17894ac82427360a6c88d259ada520eb49ff/argocd-tool-diff-gist.yaml"
]
agent_integrations = ["slack"]
agent_environment_variables = {
    #DEBUG           = "1"
    LOG_LEVEL       = "INFO"
    ARGOCD_SERVER = "argocd-server.argocd"
    ARGOCD_USERNAME = "admin"
}

agent_ai_instructions = <<EOF
You are an intelligent agent able to give the diff between a live argocd app state
and a specified revision using the argocd CLI diff command.
EOF
