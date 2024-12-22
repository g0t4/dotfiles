#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unreachable_code)]

use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

static SYSTEM_MESSAGE: &str = "You are a command line expert. Respond with a single, valid, complete command line. I intend to execute it. No explanation. No markdown. No markdown with backticks ` nor ```";

static SYSTEM_MESSAGE_DEVTOOLS: &str = "
You are a chrome devtools expert.
The user is working in the devtools Console in the Brave Beta Browser.
The user needs help completing a javascript command.
Whatever they have typed into the Console's command line will be provided to you.
They might also have a free-form question included, i.e. in a comment (after //).
Respond with a single, valid javascript command line. Their command line will be replaced with your response. So they can review and execute it.
No explanation. No markdown. No markdown with backticks ` nor ```.

An example of a command line could be `find the first div on the page` and a valid response would be `document.querySelector('div')`
";

//static SECURITY_ACCOUNT: &str = "openai";
static SECURITY_ACCOUNT: &str = "groq";
//static MODEL: &str = "gpt-4o";
static MODEL: &str = "llama-3.1-70b-versatile"; // TODO newer groq model?

//static URL: &str = "https://api.openai.com/v1/chat/completions";
static URL: &str = "https://api.groq.com/openai/v1/chat/completions";

// TODO test w/ and w/o async... I don't think async has a benefit but I am curious how much overhead it adds
// reimpl as SYNC

#[tokio::main]
async fn main() {
    let mut input = String::new();
    io::stdin()
        .read_to_string(&mut input)
        .expect("Failed to read from stdin");
    //println!("Input: {:?}", input);

    // TODO read in config for which service to use (openai,groq, ... and add this to timing)

    let output = std::process::Command::new("security")
        .arg("find-generic-password")
        .arg("-s")
        .arg(SECURITY_ACCOUNT)
        .arg("-a")
        .arg("ask")
        .arg("-w")
        .output();
    let api_key = String::from_utf8(output.unwrap().stdout)
        .unwrap()
        .trim()
        .to_string();
    //println!("API Key: {}", api_key);

    let request = ChatCompletionRequest {
        model: MODEL.to_string(),
        messages: vec![
            Message {
                role: "system".to_string(),
                content: SYSTEM_MESSAGE_DEVTOOLS.to_string(),
            },
            Message {
                role: "user".to_string(),
                content: input,
            },
        ],
        max_tokens: 200,
    };

    match send_openai_request(&api_key, request).await {
        Ok(response) => println!("{}", response.choices[0].message.content),
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

    //// uncomment to test everything except calling the API... 27.5ms yes!
    //println!("Request: {:#?}", request);
    //return Ok(ChatCompletionResponse {
    //    choices: vec![Choice {
    //        message: Message {
    //            role: "assistant".to_string(),
    //            content: "short ciruct testing".to_string(),
    //        },
    //    }],
    //});

    let response = client
        .post(URL)
        .header("Authorization", format!("Bearer {}", api_key))
        .json(&request)
        .send()
        .await?;

    //println!("Response: {:?}", response); // dump compact, doesn't show body AFAICT
    //println!("Response: {:#?}", response); // dump pretty

    if !response.status().is_success() {
        println!("FAIL, response status: {}", response.status());
    }
    let result = response.json::<ChatCompletionResponse>().await?;
    //println!("Result: {:#?}", result); // dump pretty, bound data
    Ok(result)
}
