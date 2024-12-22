#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unreachable_code)]

use dirs;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

// TODO new switching mechanism so I can keep one binary for all cases... I need this to be passed from caller (as arg, or env var, or I could symlink same binary to diff names for - single,devtools,links,etc)
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

// TODO test w/ and w/o async... I don't think async has a benefit but I am curious how much overhead it adds
// reimpl as SYNC

#[tokio::main]
async fn main() {
    let mut input = String::new();
    io::stdin()
        .read_to_string(&mut input)
        .expect("Failed to read from stdin");

    let service = get_service();

    let api_key = get_api_key(service.name.to_string());

    let request = ChatCompletionRequest {
        model: service.model.to_string(),
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

    match send_openai_request(&api_key, service, request).await {
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
    service: Service,
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
        .post(service.url)
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

#[derive(Debug)]
struct Service {
    name: String,
    model: String,
    url: String,
}

fn get_service() -> Service {
    let home_dir = dirs::home_dir().expect("Could not find home directory");
    let file_path = home_dir.join(".local/share/ask/service");
    let contents = std::fs::read_to_string(file_path).expect("Could not read file");
    // contents looks like:
    // --ollama model-1
    let service = contents.split(" ").collect::<Vec<&str>>();
    let model = if service.len() > 1 {
        Some(service[1].trim())
    } else {
        None
    };
    match service[0].trim() {
        // PRN add more from services.py when I wanna use them
        "--groq" => {
            return Service {
                name: "groq".to_string(),
                model: if model.is_some() {
                    model.unwrap().to_string()
                } else {
                    "llama-3.1-70b-versatile".to_string()
                },
                url: "https://api.groq.com/openai/v1/chat/completions".to_string(),
            };
        }
        "--ollama" => {
            return Service {
                name: "ollama".to_string(),
                model: if model.is_some() {
                    model.unwrap().to_string()
                } else {
                    "llama3.2:3b".to_string()
                },
                url: "http://localhost:11434/v1/chat/completions".to_string(),
            };
        }
        _ => {
            // OpenAI is the default
            return Service {
                name: "openai".to_string(),
                model: if model.is_some() {
                    model.unwrap().to_string()
                } else {
                    "gpt-4o".to_string()
                },
                url: "https://api.openai.com/v1/chat/completions".to_string(),
            };
        }
    }
}

fn get_api_key(service_name: String) -> String {
    // TODO make work on windows or leave windows pointed at python impl
    // Install-Module -Name CredentialManager -Force
    // $credential = Get-StoredCredential -Target "YourTargetName"
    let output = std::process::Command::new("security")
        .arg("find-generic-password")
        .arg("-s")
        .arg(service_name)
        .arg("-a")
        .arg("ask")
        .arg("-w")
        .output();

    return String::from_utf8(output.unwrap().stdout)
        .unwrap()
        .trim()
        .to_string();
    // TODO error handling
}
