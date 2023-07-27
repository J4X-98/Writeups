from web3 import Web3

def generate_keccak256_hash(word):
    return Web3.keccak(text=word).hex()

def main():
    prefix_to_check = "0xe2c8f"
    wordlist_file = "wordlist.txt"

    with open(wordlist_file, "r") as f:
        words = f.read().splitlines()

    for word in words:
        hash_value = generate_keccak256_hash(word)
        if hash_value.startswith(prefix_to_check):
            print(f"Found word: {word}, leading to hash: {hash_value}")

if __name__ == "__main__":
    main()