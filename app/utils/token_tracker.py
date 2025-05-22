total_tokens = 0

def add_tokens(tokens: int):
    global total_tokens
    total_tokens += tokens

def get_total_tokens():
    return total_tokens