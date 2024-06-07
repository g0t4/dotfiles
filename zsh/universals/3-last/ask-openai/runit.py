import subprocess
import sys
from os import getenv
from openai import OpenAI

from services import args_to_use, use_openai, Service


def generate_script(passed_context: str, use: Service) -> str:

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": """You are a macOS expert. For each request, generate a script with PYTHON or BASH that starts with a valid SHEBANG. If a request has multiple parts, make sure to include all of it in one go. I will execute the code you give me (once I approve it)... no explanations beyond comments and only use that sparingly. If a change requires restarting a program, make sure to do that too... i.e. killall Finder/SystemUIServer/Dock/etc as needed. Prefer simple code.

                    DO NOT return markdown code blocks ``` or `"""
                },
                {
                    "role": "user",
                    "content": f"Please help me with the following request: {passed_context}"
                },
            ],
            max_tokens=1000,
            n=1  # default
        )

        response = completion.choices[0].message.content

        log_response(passed_context, use, response)
        return response

    except Exception as e:
        print(f"{e}")
        return None


def log_response(passed_context: str, use: Service, response: str):
    log_file = f"{getenv('HOME')}/.ask.openai.runit.log"
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


def main():

    TEST = False

    use = use_openai()
    # TODO for now I wanna use args just for passing question b/c STDIN needs to be interactive to approve execution
    script_file = sys.argv[1]  # assume all in first arg, "" ed
    with open(script_file, "r", encoding='utf-8') as file:
        script_lines = file.readlines()
    for line in script_lines:
        if line.startswith("#") or line == "\n":
            continue
        print(f"## Running: {line}", end='')
        suggested_script = generate_script(line, use)
        bat = subprocess.Popen(["bat", "--style", "plain", "--color=always"], stdin=subprocess.PIPE)
        bat.communicate(input=suggested_script.encode())
        bat.stdin.close()
        bat.wait()

        print("\n## EXECUTE?")
        try:
            input("Press Enter to execute, Ctrl+C to reject...")
        # IDEA SKIP current command
        # IDEA redo suggestion
        # IDEA add qualification and update script file with it?
        except KeyboardInterrupt:
            print("Abort...")
            sys.exit(1)

        print("\n")
        # run the python:
        # exec(python)
        subprocess.run(["bash", "-c", suggested_script])


if __name__ == "__main__":
    main()
