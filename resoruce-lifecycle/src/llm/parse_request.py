import os
import json
from litellm import completion
from pydantic import ValidationError
from models.models import ParsedRequest, TerraformCode
from models.constants import SYSTEM_PROMPT_TEMPLATE, TERRAFORM_CODE_PROMPT_TEMPLATE, TERRAFORM_CODE_FIX_PROMPT_TEMPLATE

def validate_json_structure(json_data):
    try:
        # Strip ```json tags if present
        if json_data.startswith("```json"):
            json_data = json_data[7:]
        if json_data.endswith("```"):
            json_data = json_data[:-3]

        data = json.loads(json_data)
        parsed_request = ParsedRequest(**data)
        return True, parsed_request
    except (json.JSONDecodeError, ValidationError) as e:
        log_message = f"Error in parsing request: {e}, for data: {json_data}"
        print(log_message)
        return False, str(e)

def parse_user_request(user_input):
    sys_prompt = SYSTEM_PROMPT_TEMPLATE.format(
        allowed_vendors=os.getenv('ALLOWED_VENDORS', 'aws'),
        user_input=user_input
    )

    messages = [
        {"content": sys_prompt, "role": "system"},
        {"content": user_input, "role": "user"}
    ]

    response = completion(model="gpt-4o", messages=messages, format="json")

    try:
        parsed_response = response['choices'][0]['message']['content']
        
        # Ensure the response is correctly formatted JSON
        if parsed_response.startswith("```json"):
            parsed_response = parsed_response[7:]
        if parsed_response.endswith("```"):
            parsed_response = parsed_response[:-3]

        is_valid, result = validate_json_structure(parsed_response)

        if not is_valid:
            parsed_response = {
                "resource_details": {},
                "vendor": "",
                "natural_language_description": user_input,
                "missing_details_message": f"Error in parsing request: {result}"
            }
            print(f"Unable to get resource details from your request: {parsed_response['missing_details_message']}")
            return None, parsed_response

        return result, None
    except Exception as e:
        error_message = f"Error in processing response: {e}"
        parsed_response = {
            "resource_details": {},
            "vendor": "",
            "natural_language_description": user_input,
            "missing_details_message": error_message
        }
        print(f"Unable to get resource details from your request: {error_message}")
        return None, parsed_response

def generate_terraform_code(resource_details):
    sys_prompt = TERRAFORM_CODE_PROMPT_TEMPLATE.format(resource_details=json.dumps(resource_details, indent=2))

    messages = [{"content": sys_prompt, "role": "system"}]

    response = completion(
        model="gpt-4o",
        messages=messages,
        format="json"
    )

    try:
        tf_files_and_explanation = response['choices'][0]['message']['content']
        
        # Ensure the response is correctly formatted JSON
        if tf_files_and_explanation.startswith("```json"):
            tf_files_and_explanation = tf_files_and_explanation[7:]
        if tf_files_and_explanation.endswith("```"):
            tf_files_and_explanation = tf_files_and_explanation[:-3]

        tf_files_and_explanation = json.loads(tf_files_and_explanation)

        tf_files = tf_files_and_explanation.get("tf_files")
        tf_code_explanation = tf_files_and_explanation.get("tf_code_explanation")

        return TerraformCode(tf_files=tf_files, tf_code_explanation=tf_code_explanation)
    except Exception as e:
        error_message = f"Error in generating Terraform code: {e}"
        print(error_message)
        raise ValueError(error_message)

def fix_terraform_code(tf_files, error_message):
    sys_prompt = TERRAFORM_CODE_FIX_PROMPT_TEMPLATE.format(error_message=error_message, tf_code=json.dumps(tf_files))

    messages = [{"content": sys_prompt, "role": "system"}]

    response = completion(
        model="gpt-4o",
        messages=messages,
        format="json"
    )

    try:
        tf_files_and_explanation = response['choices'][0]['message']['content']
        
        # Ensure the response is correctly formatted JSON
        if tf_files_and_explanation.startswith("```json"):
            tf_files_and_explanation = tf_files_and_explanation[7:]
        if tf_files_and_explanation.endswith("```"):
            tf_files_and_explanation = tf_files_and_explanation[:-3]

        tf_files_and_explanation = json.loads(tf_files_and_explanation)

        tf_files = tf_files_and_explanation.get("tf_files")
        tf_code_explanation = tf_files_and_explanation.get("tf_code_explanation")

        return TerraformCode(tf_files=tf_files, tf_code_explanation=tf_code_explanation)
    except Exception as e:
        error_message = f"Error in fixing Terraform code: {e}"
        print(error_message)
        raise ValueError(error_message)

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Parse the user request.')
    parser.add_argument('user_input', type=str, help='The natural language request from the user')

    args = parser.parse_args()
    result, error = parse_user_request(args.user_input)
    if result:
        print(f"Parsed request details: {result}")
    else:
        print(f"Error: {error}")
