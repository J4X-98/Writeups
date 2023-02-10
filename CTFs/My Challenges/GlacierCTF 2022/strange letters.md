Description:

You are provided with an image that contains a bunch of strange letters.

Challenge Code:

https://github.com/LosFuzzys/GlacierCTF2022/tree/main/crypto/strange_letters

Solution:

Numbers are written using the cisterian monks numeral system. 
https://www.reddit.com/r/coolguides/comments/lc0fo6/the_cistercian_monks_invented_a_numbering_system/

1. Decode the numbers, using a tool like https://www.dcode.fr/cistercian-numbers
2. Keep all 0s and append all numbers together into one big one.
3. Convert the number hex/bytes
4. Convert to ASCII / print to get the flag.
