from secrets import token_bytes
from coincurve import PublicKey
from sha3 import keccak_256

def generate_public_key(private_key):
    public_key = keys.PrivateKey(bytes(private_key, 32)).public_key
    return public_key

def check_addr(address):
    address = int.from_bytes(address, 'big') & 0xFFFF000000000000000000000000000
    address = address >> 108
    return address == 13057

found_key = False

for i in range(pow(2, 16)):
    private_key = keccak_256(token_bytes(32)).digest()

    public_key = PublicKey.from_valid_secret(private_key).format(compressed=False)[1:]
    addr = keccak_256(public_key).digest()[-20:]

    print("Private Key:", private_key.hex())
    print("Public Key:", public_key.hex())
    print("Address:", addr.hex())

    if check_addr(addr):
        found_key = True
        print("Key found")
        break

