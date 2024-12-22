use reqwest::Client;
use serde::{Deserialize, Serialize};

// TODO test w/ and w/o async... I don't think async has a benefit but I am curious how much overhead it adds
// reimpl as SYNC

#[tokio::main]
async fn main() {
    let output = std::process::Command::new("security")
        .arg("find-generic-password")
        .arg("-s")
        .arg("openai")
        .arg("-a")
        .arg("ask")
        .arg("-w")
        .output();
    let api_key = String::from_utf8(output.unwrap().stdout)
        .unwrap()
        .trim()
        .to_string();
    //println!("API key: {}", api_key);

    // Prepare the request body
    let request = OpenAIRequest {
        model: "text-davinci-003".to_string(),
        prompt: "Tell me a joke.".to_string(),
        max_tokens: 50,
    };

    match send_openai_request(&api_key, request).await {
        Ok(response) => println!("Response: {}", response.choices[0].text),
        Err(e) => eprintln!("Error: {}", e),
    }
}

#[derive(Serialize)]
struct OpenAIRequest {
    model: String,
    prompt: String,
    max_tokens: u32,
}

#[derive(Deserialize)]
struct OpenAIResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    text: String,
}

async fn send_openai_request(
    api_key: &str,
    request: OpenAIRequest,
) -> Result<OpenAIResponse, reqwest::Error> {
    let client = Client::new();
    let url = "https://api.openai.com/v1/completions";

    let response = client
        .post(url)
        .header("Authorization", format!("Bearer {}", api_key))
        .json(&request)
        .send()
        .await?;

    let result = response.json::<OpenAIResponse>().await?;
    Ok(result)
}
