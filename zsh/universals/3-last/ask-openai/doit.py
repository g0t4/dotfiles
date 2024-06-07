import subprocess
import sys
from os import getenv
from openai import OpenAI

from services import args_to_use, use_openai, Service


def generate_python_script(passed_context: str, use: Service) -> str:

    client = OpenAI(api_key=use.api_key, base_url=use.base_url)

    try:

        completion = client.chat.completions.create(
            model=use.model,
            messages=[
                {
                    "role": "system",
                    "content": """You are a macOS expert. For each request, generate a script with PYTHON or BASH that starts with a valid SHEBANG. If a request has multiple parts, make sure to include all of it in one go. I will execute the code you give me (once I approve it)... no explanations beyond comments and only use that sparingly. If a change requires restarting a program, make sure to do that too... i.e. killall Finder

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
    log_file = f"{getenv('HOME')}/.ask.openai.doit.log"
    with open(log_file, "a", encoding='utf-8') as file:
        file.writelines([f"{'#'*40} {use.base_url} {use.model}" + '\n', f"{passed_context}\n{response}\n\n"])


def main():

    TEST = False

    if not TEST:
        use = use_openai()
        # TODO for now I wanna use args just for passing question b/c STDIN needs to be interactive to approve execution
        user_request = sys.argv[1]  # assume all in first arg, "" ed
        print(
            f"## REQUEST: {user_request}")  # tmp validate request passed while I iterate on this initial script, cuz I will make more idiot mistakes
        python = generate_python_script(user_request, use)
    else:
        # test case:
        python = 'subprocess.run(["defaults", "write", "-g", "AppleAccentColor", "-int", "4"])'

    # PRN strip markdown code blocks? its hard to get it to knock that off probably given prevalence of code blocks in markdown in training sets... just get a library to remove them => ADD unit test for this logic
    # python = re.sub(r'```.*?```', '', python, flags=re.DOTALL)

    print("## PROPOSED:")
    # pipe to bat for syntax highlighting:
    bat = subprocess.Popen(["bat", "--style", "plain", "--color=always"], stdin=subprocess.PIPE)
    bat.communicate(input=python.encode())
    bat.stdin.close()
    bat.wait()

    print("\n")

    # # validate valid python (TODO ADD BACK WHEN SHEBANG is PYTHON)
    # try:
    #     compile(python, 'generated_script', 'exec')
    # except SyntaxError as e:
    #     print(f"Syntax Error: {e}")
    #     sys.exit(1)

    # read ENter from user
    print("## EXECUTE?")
    try:
        input("Press Enter to execute, Ctrl+C to reject...")
    except KeyboardInterrupt:
        print("Rejected.")
        sys.exit(1)

    # PRN for long scripts, perhaps it could be split up... into key steps, and I could ask openai to do that too, to put in markers OR to stream one block at a time and then allow me to course correct along the way? that does start to bleed into the domain of my Ctrl+B ask open helper but maybe that is the direction this could go (to be more interactive and make what I am starting to think of as ESH => English langauge SHell)... OMG makes me wanna make a script parser and start on english language scripts and have it run interactively with thresholds for approval!!! OMG COOL

    print("\n")
    # run the python:
    # exec(python)
    subprocess.run(["bash", "-c", python])


if __name__ == "__main__":
    main()
