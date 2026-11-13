"""Common LangChain connection to dedicated llama-server endpoints or routers."""

import httpx


def select_model(models, setting="model override"):
    available = [m for m in models if isinstance(m.get("id"), str) and m["id"]]
    if len(available) == 1:
        return available[0]["id"]
    loaded = [m for m in available if m.get("status", {}).get("value") == "loaded"]
    if len(loaded) == 1:
        return loaded[0]["id"]
    raise ValueError(
        f"Cannot select a unique served model; set {setting} to an ID from /v1/models"
    )


def connect(base_url, model=None, api_key="none", setting="model override"):
    from langchain_llama_server.chat_models import ChatLlamaServer

    if not model:
        response = httpx.get(
            base_url.rstrip("/") + "/models",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=10,
        )
        response.raise_for_status()
        model = select_model(response.json().get("data", []), setting)
    return ChatLlamaServer(
        base_url=base_url, model=model, api_key=api_key, timeout=120, max_retries=0
    )
