import os
import subprocess
import logging
from typing import Tuple, Dict

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def run_terraform_command(command: list) -> Tuple[bool, str]:
    try:
        result = subprocess.run(command, check=True, capture_output=True)
        return True, result.stdout.decode('utf-8')
    except subprocess.CalledProcessError as e:
        logging.error(f"Error running {' '.join(command)}: {e.stderr.decode('utf-8')}")
        return False, e.stderr.decode('utf-8')

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
        
        log_path = f"/tf_logs/{request_id}/"
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
    
    log_path = f"/tf_logs/{request_id}/"
    os.makedirs(log_path, exist_ok=True)
    with open(os.path.join(log_path, "destroy.log"), "w") as log_file:
        log_file.write(destroy_output)
    return destroy_output
