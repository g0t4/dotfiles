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

    let request = OpenAIRequest {
        model: "gpt-4o".to_string(),
        prompt: "Tell me a joke.".to_string(),
        max_tokens: 200,
    };

    match send_openai_request(&api_key, request).await {
        Ok(response) => println!("Response: {:#?}", response),
        Err(e) => eprintln!("Error: {}", e),
    }
}

#[derive(Serialize)]
struct OpenAIRequest {
    model: String,
    prompt: String,
    max_tokens: u32,
}

#[derive(Deserialize, Debug)]
struct OpenAIResponse {
    //choices: Vec<Choice>,
    data: Vec<ModelData>,
}

#[derive(Deserialize, Debug)]
struct ModelData {
    id: String,
    object: String,
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
    let url = "https://api.openai.com/v1/models";

    let response = client
        .get(url)
        .header("Authorization", format!("Bearer {}", api_key))
        //.json(&request)
        .send()
        .await?;

    //println!("Response: {:?}", response); // dump compact, doesn't show body AFAICT
    println!("Response: {:#?}", response); // dump pretty

    if !response.status().is_success() {
        println!("FAIL, response status: {}", response.status());
    }
    let result = response.json::<OpenAIResponse>().await?;
    println!("Result: {:#?}", result); // dump pretty, bound data
    Ok(result)
}
