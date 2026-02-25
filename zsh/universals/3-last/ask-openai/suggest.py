from services import Service
import httpx  # import alone is ~58ms

# TODO replace w/ new langchain IMPL that handles both

def generate(passed_context: str, system_message: str, use: Service, max_tokens: int):
    if use.name == "anthropic":
        return get_anthropic_suggestion(passed_context, system_message, use, max_tokens)
    else:
        return get_openai_suggestion(passed_context, system_message, use, max_tokens)


def get_openai_suggestion(passed_context: str, system_message: str, use: Service, max_tokens: int):
    http_client = httpx.Client()
    try:
        body = {
            "model": use.model,
            "messages": [
                {
                    "role": "system",
                    "content": system_message
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            "max_tokens": max_tokens,
            "n": 1  # default
        }
        chat_url = use.chat_url()
        headers = {
            "Authorization": f"Bearer {use.api_key}",
            "Content-Type": "application/json",
        }
        response = http_client.post(chat_url, json=body, headers=headers)
        response.raise_for_status()
        completion = response.json()
        return completion["choices"][0]["message"]["content"]
    except httpx.HTTPStatusError as e:
        # this is triggered by raise_for_status and gives me access to resopnse body
        #   i.e. useful with ollama when I request invalid model, the body explains that where as w/o the body its a generic 404 which is frustrating at best
        print(f"HTTP error occurred: {e}")
        print(f"Response body: {e.response.text}")  # response body
    except Exception as e:
        print(f"{e}")
        return None


def get_anthropic_suggestion(passed_context: str, system_message: str, use: Service, max_tokens: int):
    http_client = httpx.Client()
    try:
        # https://docs.anthropic.com/en/api/messages
        body = {
            # TODO how does this perform vs as user message? same question for openai compat above
            #  FYI I tested that role: "system" appears fine for both openai and claude, is there any benefit one way or the other, I'll just wait to see if cmd suggestions suck
            "system": system_message,
            "model": use.model,
            "messages": [
                {
                    "role": "user",
                    "content": f"{passed_context}"
                },
            ],
            "max_tokens": max_tokens,
        }
        chat_url = use.chat_url()
        headers = {
            "x-api-key": f"{use.api_key}",
            "Content-Type": "application/json",
            "anthropic-version": "2023-06-01",
        }
        response = http_client.post(chat_url, json=body, headers=headers)
        response.raise_for_status()
        completion = response.json()
        return completion["content"][0]["text"]
    except httpx.HTTPStatusError as e:
        print(f"HTTP error occurred: {e}")
        print(f"Response body: {e.response.text}")  # response body
    except Exception as e:
        print(f"{e}")
        return None
