agent_name = "argo-diff-test-tf"
agent_runners = "aks-dev"
agent_description = "used to test argocd diff tool"
agent_llm_model = "azure/gpt-4"

agent_integrations = ["slack"]
agent_environment_variables = {
    DEBUG           = "1"
    LOG_LEVEL       = "INFO"
    ARGOCD_SERVER = "argocd-server.argocd"
    ARGOCD_USERNAME = "admin"
    KUBIYA_TOOL_CONFIG_URLS = "https://gist.githubusercontent.com/EvgeniyReich/24865746c00a1eaf1a87044465f0ecf1/raw/c2b123215855471068a7d680bb0e0f4b4353a4fc/argocd-tool-diff-gist.yaml"
}

agent_ai_instructions = <<EOF
when asked, you use the tool provided to you to install Argocd cli, login to it and get the diff between a live argocd app state and the state of a specific revision.
Use the env vars ARGOCD_SERVER, ARGOCD_USERNAME and ARGOCD_PASSWORD to login.
Always use the flags '--insecure' and '--plaintext' when logging in to argocd. 
Ask the user  for the value of argo_app_name and revision vars every time the diff command is called and use them in the command.
Use the '--revision' flag before the 'revision' variable in the command.
EOF
