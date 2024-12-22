import keyring  # 63ms to load (per hyperfine)

# 120ms (regardless if password exists or not) # hyperfine -- 'python3 -c "from tests.keyring import main; main()"'
# 30ms # hyperfine -- 'security find-generic-password -s openai -a ask -w'


def main():
    # main separated to split import testing vs get_password testing
    foo = keyring.get_password("sopenai", "ask")  # 60ms to run per hyperfine... holy crap
    # print(foo)
    return
