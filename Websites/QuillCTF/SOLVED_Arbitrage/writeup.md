# Arbitrage

## Challenge

We are provided with a standard uniswapv2 router and 5 tokens that are added to it as pairs with different liquidities. You get 5 btokens and your goal is to increase your count.

## Solution

I wrote a python script that checks for all possible paths from btoken -> btoken. Then it calculates the final value after all the transactions were done. If the value is bigger than 5 it prints. 

```python
liquidity = {
    ('Atoken', 'Btoken'): (17, 10),
    ('Atoken', 'Ctoken'): (11, 7),
    ('Atoken', 'Dtoken'): (15, 9),
    ('Atoken', 'Etoken'): (21, 5),
    ('Btoken', 'Ctoken'): (36, 4),
    ('Btoken', 'Dtoken'): (13, 6),
    ('Btoken', 'Etoken'): (25, 3),
    ('Ctoken', 'Dtoken'): (30, 12),
    ('Ctoken', 'Etoken'): (10, 8),
    ('Dtoken', 'Etoken'): (60, 25)
}

# Recursive helper function
def find_paths_recursive(paths, current_token, current_path, length, end_token):

    if len(current_path) == length:
        if current_token == end_token:
            paths.append(current_path)
        return paths
    
    for token_pair, _ in liquidity.items():
        if token_pair[0] == current_token:
            next_token = token_pair[1]
            paths = find_paths_recursive(paths, next_token, current_path + [next_token], length, end_token)
        elif token_pair[1] == current_token:
            next_token = token_pair[0]
            paths = find_paths_recursive(paths, next_token, current_path + [next_token], length, end_token)

    return paths

def find_paths(start_token, end_token, length):
    paths = []
    
    paths = find_paths_recursive(paths, start_token, [start_token], length, end_token)
    return paths

def calculate_output(tokenin, tokenout, amountin):

    for token_pair, _ in liquidity.items():
        if token_pair[0] == tokenin and token_pair[1] == tokenout:
            return amountin * 997 * liquidity [token_pair][1] / (liquidity[token_pair][0] * 1000 + amountin * 0.997)

        elif token_pair[1] == tokenin and token_pair[0] == tokenout:
            return amountin * 997 * liquidity [token_pair][0] / (liquidity[token_pair][1] * 1000 + amountin * 0.997)
    return 0


# Starting token and initial balance of B-token
possible_paths = []

for k in range(2,11):
    found_paths = find_paths('Btoken', 'Btoken', k)
    for path in found_paths:
        possible_paths.append(path)

for path in possible_paths:
    balance = 5
    for i in range(len(path)-1):
        balance = calculate_output(path[i], path[i+1], balance)

    if balance > 5:
        print(path)
        print(balance)
        break

```

I found a possible path[Btoken -> Atoken -> Ctoken -> Btoken] with this and ran it which worked.
The implementation can be found in the POC.sol file.