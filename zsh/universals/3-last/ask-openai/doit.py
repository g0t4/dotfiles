import subprocess
import sys
from os import getenv
from openai import OpenAI

from services import args_to_use, Service


def generate_python_script(passed_context: str, use: Service) -> str:

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": "You are a preferences expert on macOS, i.e. how to use defaults commmand to change the accent color... I will request a change to macOS preferences and I want you to generate PYTHON CODE ONLY that invokes SHELL COMMANDS as needed to make the change. I will execute the code you give me (once I approve it)... no explanations beyond comments and only use that sparingly, i.e. to draw my attention to a something risky. I may ask you to do things beyond just preferences, please comply as long as you feel confident. Do not return markdown code blocks, this has to be pure python."
                },
                {
                    "role": "user",
                    "content": f"{passed_context}"
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
    log_file = f"{getenv('HOME')}/.ask.openai.doit.log"
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


def main():

    # use = args_to_use()
    # TODO use chatgpt only for now?
    # stdin_context = sys.stdin.read()

    # python = generate_python_script(stdin_context, use)
    python = 'subprocess.run(["defaults", "write", "-g", "AppleAccentColor", "-int", "4"])'  # test case

    print("## PROPOSED:")
    with open("generated_script.py", "w") as file:
        file.write(python)
    # invoke bat to syntax highlight
    subprocess.run(["bat", "generated_script.py"], check=True)
    print()
    print()

    # validate valid python
    try:
        compile(python, 'generated_script', 'exec')
    except SyntaxError as e:
        print(f"Syntax Error: {e}")
        sys.exit(1)

    # read ENter from user
    print("## EXECUTE?")
    input("Press Enter to execute, Ctrl+C to reject...")
    print()
    # run the python:
    exec(python)


if __name__ == "__main__":
    main()
