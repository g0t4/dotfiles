#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unreachable_code)]

use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

// TODO test w/ and w/o async... I don't think async has a benefit but I am curious how much overhead it adds
// reimpl as SYNC

#[tokio::main]
async fn main() {
    let mut input = String::new();
    io::stdin()
        .read_to_string(&mut input)
        .expect("Failed to read from stdin");
    println!("Input: {:?}", input);

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

    let request = ChatCompletionRequest {
        model: "gpt-4o".to_string(),
        messages: vec![Message {
            role: "user".to_string(),
            content: "What is the best way to learn Rust?".to_string(),
        }],
        max_tokens: 200,
    };

    match send_openai_request(&api_key, request).await {
        Ok(response) => println!("Response: {:#?}", response),
        Err(e) => eprintln!("Error: {}", e),
    }
}

// TODO should I remove the auto-derives for Debug, how much overhead does that add?
#[derive(Serialize, Debug)]
struct ChatCompletionRequest {
    model: String,
    messages: Vec<Message>,
    max_tokens: u32,
    // PRN? n: 1
}

#[derive(Deserialize, Serialize, Debug)]
struct Message {
    role: String,
    content: String,
}

#[derive(Deserialize, Debug)]
struct ChatCompletionResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize, Debug)]
struct Choice {
    message: Message,
}

async fn send_openai_request(
    api_key: &str,
    request: ChatCompletionRequest,
) -> Result<ChatCompletionResponse, reqwest::Error> {
    let client = Client::new();
    let url = "https://api.openai.com/v1/chat/completions";

    #[cfg(feature = "perf_without_api_call")]
    {
        // toggle this true to test everything except calling the API... 27.5ms yes!
        println!("Request: {:#?}", request);
        return Ok(ChatCompletionResponse {
            choices: vec![Choice {
                message: Message {
                    role: "assistant".to_string(),
                    content: "short ciruct testing".to_string(),
                },
            }],
        });
    }

    let response = client
        .post(url)
        .header("Authorization", format!("Bearer {}", api_key))
        .json(&request)
        .send()
        .await?;

    //println!("Response: {:?}", response); // dump compact, doesn't show body AFAICT
    println!("Response: {:#?}", response); // dump pretty

    if !response.status().is_success() {
        println!("FAIL, response status: {}", response.status());
    }
    let result = response.json::<ChatCompletionResponse>().await?;
    println!("Result: {:#?}", result); // dump pretty, bound data
    Ok(result)
}
