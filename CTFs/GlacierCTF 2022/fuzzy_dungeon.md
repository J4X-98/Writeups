Description:

The challenge is a dungeon crawler RPG. The goal is to defeat the boss at the end to receive the flag. The problem is that by using the game mechanics, the boss can't be defeated.

Challenge Code:

https://github.com/LosFuzzys/GlacierCTF2022/tree/main/misc/fuzzy_dungeon

Solution:

There is one room that allows to downgrade the damage of your character. As the damage is an unsigned int, if you hit the wall in the one room often enough, your damage underflows and you easily defeat everyone.

Tasks:

Go Straight
Go Left
Go Straight
Go Left
Hit Wall until your damage underflows
Go Right
Go Right
Go Straight
Go Left.
Go Straight
Go Right
Defeat Boss -> Flag