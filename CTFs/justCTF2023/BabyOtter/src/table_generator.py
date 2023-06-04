VECTOR_SIZE = 256

def gt():
    table = []
    i = 0

    while i < VECTOR_SIZE:
        tmp = i
        j = 0

        while j < 8:
            if tmp & 1:
                tmp = tmp >> 1
                tmp = tmp ^ 0xedb88320
            else:
                tmp = tmp >> 1

            j = j + 1

        table.append(tmp)
        i = i + 1

    return table

def main():
    result = gt()

    print(result)

    # Sort the vector by value
    sorted_indices = sorted(range(len(result)), key=lambda x: result[x])
    sorted_values = [result[i] for i in sorted_indices]

    # Print the sorted values with their indices, one per line
    for i, value in zip(sorted_indices, sorted_values):
        last_4_bytes = value & 0xFFFFFFFF  # Mask to keep only the last 4 bytes
        print(f"Index: {i}, Value: {format(last_4_bytes, '08x')}")

if __name__ == '__main__':
    main()
