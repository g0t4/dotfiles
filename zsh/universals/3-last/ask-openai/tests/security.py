import subprocess


def main():
    try:
        cmd = ['security', 'find-generic-password', '-s', 'openai', '-a', 'ask', '-w']
        result = subprocess.run(cmd, text=True, capture_output=True, check=True)
        print("Output:", result.stdout)
    except subprocess.CalledProcessError as e:
        print("Command failed!")
        print("Error:", e.stderr)


if __name__ == '__main__':
    main()
