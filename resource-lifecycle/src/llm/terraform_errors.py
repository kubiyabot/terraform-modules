import json
from time import sleep
from typing import Any, Dict
from litellm import completion
from pydantic import BaseModel, ValidationError

class CodeUnrecoverableLLMResponse(BaseModel):
    unrecoverable_error: bool
    reasoning: str

def is_error_unrecoverable(error: str, max_retries: int = 3, delay: int = 2) -> CodeUnrecoverableLLMResponse:
    sys_prompt = f"CAREFULLY READ the error message below and determine if it is an unrecoverable error. For example, if the error is due to a syntax error in the Terraform code, it may be unrecoverable. If the error is due to a missing resource, it may be recoverable. Please provide your decision and reasoning in the response.```{error}```\n\nReturn a json object with the following keys: `unrecoverable_error` (boolean) and `reasoning` (string)."

    messages = [{"content": sys_prompt, "role": "system"}]

    for attempt in range(max_retries):
        try:
            response = completion(
                model="gpt-4o",
                messages=messages,
                format="json"
            )
            llm_response = response['choices'][0]['message']['content']

            # Parse the response to ensure it is valid JSON and matches the expected format
            parsed_response: Dict[str, Any] = json.loads(llm_response)
            return CodeUnrecoverableLLMResponse(**parsed_response)
        except (json.JSONDecodeError, ValidationError) as e:
            print(f"Attempt {attempt + 1}/{max_retries} failed with error: {e}")
            if attempt < max_retries - 1:
                sleep(delay)
            else:
                raise e
