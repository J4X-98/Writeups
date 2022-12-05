Description:

The CTF provides you with a huge string in a .txt file

Challenge Code:

https://github.com/LosFuzzys/GlacierCTF2022/tree/main/crypto/simple_crypto

Solution:

The encoding is a spartan cipher with an offset of 30 and steps of 100. I wrote a quick python script to solve. 

f = open("ciphertext.txt", "r")
ciphertext = f.read()

##Solution
flagformat= "glacierctf{"

for i in range(50):
    for j in range(1, len(ciphertext)//8):
        iterations = len(ciphertext)//j
        end_string = ""
        for k in range(iterations):
            if (k < len(flagformat) and ciphertext[i+k*j] != flagformat[k]):
                ##print("Break")
                break

            end_string += ciphertext[i+k*j]

            if (k == iterations-1):
                print("i = " + str(i) + "\n j = " + str(j))
                print(end_string)

