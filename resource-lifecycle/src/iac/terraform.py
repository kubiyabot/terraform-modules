import os
import subprocess
import logging
from typing import Tuple, Dict

# Set environment variables and defaults
SHOW_TF_OUTPUT = os.getenv("SHOW_TF_OUTPUT", "true").lower() == "true"
LOGS_PATH = os.getenv("LOGS_PATH", "/tf_logs")
LOGS_ENABLED = os.getenv("LOGS_ENABLED", "false").lower() == "true"

# Configure logging based on LOGS_ENABLED
if LOGS_ENABLED:
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
else:
    logging.basicConfig(level=logging.INFO, format='%(message)s')

COMMON_ERRORS = {
    "resource already exists": "Resource with the given name already exists.",
    "insufficient permissions": "Insufficient permissions to perform this operation.",
    "network issue": "Network issue encountered during operation.",
    "invalid credentials": "Invalid AWS credentials provided.",
    "out of memory": "Out of memory error occurred.",
}

def run_terraform_command(command: list) -> Tuple[bool, str]:
    # Print the command being run
    print(f"🏃 {' '.join(command)}")
    
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    stdout_lines = []
    stderr_lines = []
    
    for stdout_line in iter(process.stdout.readline, ""):
        if SHOW_TF_OUTPUT:
            print(stdout_line.strip())
        stdout_lines.append(stdout_line.strip())
    
    for stderr_line in iter(process.stderr.readline, ""):
        if SHOW_TF_OUTPUT:
            print(stderr_line.strip())
        stderr_lines.append(stderr_line.strip())

    process.stdout.close()
    process.stderr.close()
    process.wait()

    if process.returncode == 0:
        return True, "\n".join(stdout_lines)
    else:
        error_output = "\n".join(stderr_lines)
        specific_error = check_common_errors(error_output)
        return False, specific_error

def check_common_errors(error_output: str) -> str:
    for error_key, error_message in COMMON_ERRORS.items():
        if error_key in error_output.lower():
            return error_message
    return error_output

def prepare_plan_path(request_id: str) -> str:
    plan_path = f"/tf_plans/{request_id}/"
    os.makedirs(plan_path, exist_ok=True)
    return plan_path

def write_tf_files(tf_files: Dict[str, str], plan_path: str) -> None:
    for filename, content in tf_files.items():
        filepath = os.path.join(plan_path, filename)
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, "w") as tf_file:
            tf_file.write(content)

def create_terraform_plan(tf_files: Dict[str, str], request_id: str) -> Tuple[bool, str, str]:
    plan_path = prepare_plan_path(request_id)
    write_tf_files(tf_files, plan_path)
    
    os.chdir(plan_path)
    os.environ["TF_IN_AUTOMATION"] = "true"
    os.environ["TF_CLI_ARGS"] = "-no-color"

    try:
        success, output = run_terraform_command(['terraform', 'init'])
        if not success:
            return False, output, None

        success, plan_output = run_terraform_command(['terraform', 'plan', '-out', f'{request_id}.tfplan'])
        if not success:
            return False, plan_output, None

        success, plan_json = run_terraform_command(['terraform', 'show', '-json', f'{request_id}.tfplan'])
        if not success:
            return False, plan_json, None

        return True, plan_output, plan_json
    except subprocess.CalledProcessError as e:
        error_output = e.stderr.decode('utf-8')
        logging.error(f"Error creating Terraform plan: {error_output}")
        specific_error = check_common_errors(error_output)
        return False, f"Error creating Terraform plan: {specific_error}", None

def apply_terraform(tf_files: Dict[str, str], request_id: str, apply: bool = False) -> Tuple[str, str]:
    plan_path = prepare_plan_path(request_id)
    write_tf_files(tf_files, plan_path)
    
    os.chdir(plan_path)
    os.environ["TF_IN_AUTOMATION"] = "true"
    os.environ["TF_CLI_ARGS"] = "-no-color"

    success, output = run_terraform_command(['terraform', 'init'])
    if not success:
        raise subprocess.CalledProcessError(returncode=1, cmd='terraform init', output=output)

    success, plan_output = run_terraform_command(['terraform', 'plan', '-out', f'{request_id}.tfplan'])
    if not success:
        raise subprocess.CalledProcessError(returncode=1, cmd='terraform plan', output=plan_output)

    if apply:
        success, apply_output = run_terraform_command(['terraform', 'apply', '-auto-approve', f'{request_id}.tfplan'])
        if not success:
            raise subprocess.CalledProcessError(returncode=1, cmd='terraform apply', output=apply_output)
        
        log_path = os.path.join(LOGS_PATH, request_id)
        os.makedirs(log_path, exist_ok=True)
        with open(os.path.join(log_path, "apply.log"), "w") as log_file:
            log_file.write(apply_output)
        return apply_output, plan_path

    return "Plan created but not applied.", plan_path

def destroy_terraform(tf_files: Dict[str, str], request_id: str) -> str:
    plan_path = prepare_plan_path(request_id)
    write_tf_files(tf_files, plan_path)
    
    os.chdir(plan_path)
    os.environ["TF_IN_AUTOMATION"] = "true"
    os.environ["TF_CLI_ARGS"] = "-no-color"

    success, output = run_terraform_command(['terraform', 'init'])
    if not success:
        raise subprocess.CalledProcessError(returncode=1, cmd='terraform init', output=output)

    success, destroy_output = run_terraform_command(['terraform', 'destroy', '-auto-approve'])
    if not success:
        raise subprocess.CalledProcessError(returncode=1, cmd='terraform destroy', output=destroy_output)
    
    log_path = os.path.join(LOGS_PATH, request_id)
    os.makedirs(log_path, exist_ok=True)
    with open(os.path.join(log_path, "destroy.log"), "w") as log_file:
        log_file.write(destroy_output)
    return destroy_output
