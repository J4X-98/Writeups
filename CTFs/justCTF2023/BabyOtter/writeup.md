# Baby Otter

## Challenge

We are provided with a challenge file in the move language:

```rs
module challenge::baby_otter_challenge {
    
    // [*] Import dependencies
    use std::vector;

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext};

    // [*] Error Codes
    const ERR_INVALID_CODE : u64 = 31337;
 
    // [*] Structs
    struct Status has key, store {
        id : UID,
        solved : bool,
    }

    // [*] Module initializer
    fun init(ctx: &mut TxContext) {
        transfer::public_share_object(Status {
            id: object::new(ctx),
            solved: false
        });
    }

    // [*] Local functions
    fun gt() : vector<u64> {

        let table : vector<u64> = vector::empty<u64>();
        let i = 0;

        while( i < 256 ) {
            let tmp = i;
            let j = 0;

            while( j < 8 ) {
                if( tmp & 1 != 0 ) {
                    tmp = tmp >> 1;
                    tmp = tmp ^ 0xedb88320;
                } else {
                    tmp = tmp >> 1;
                };

                j = j+1;
            };

            vector::push_back(&mut table, tmp);
            i = i+1;
        };

        table
    }

    fun hh(input : vector<u8>) : u64 {

        let table : vector<u64> = gt();
        let tmp : u64 = 0xffffffff;
        let input_length = vector::length(&input);
        let i = 0;

        while ( i < input_length ) {
            let byte : u64 = (*vector::borrow(&mut input, i) as u64);

            let index = tmp ^ byte;
            index = index & 0xff;

            tmp = tmp >> 8;

            tmp = tmp ^ *vector::borrow(&mut table, index);

            i = i+1;
        };

        tmp ^ 0xffffffff
    }
 
    // [*] Public functions
    public entry fun request_ownership(status: &mut Status, ownership_code : vector<u8>, _ctx: &mut TxContext) {

        let ownership_code_hash : u64 = hh(ownership_code);
        assert!(ownership_code_hash == 1725720156, ERR_INVALID_CODE);
        status.solved = true;

    }

    public entry fun is_owner(status: &mut Status) {
        assert!(status.solved == true, 0);
    }

}
```

Our goal is to make the is_owner function not revert.


## Solution

There are 2 functions inside the challenge. The first one is not depending on any input and will always return the same. It is called gt() and just generates a 256 entry long lookup table of 32bit values. I implemented the exact same functionality in python and ran it to retrieve the lookup table:

```python
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

```

This was pretty easy and, upon running yielded me the table. There also was a entry function which wanted us to pass it a vector of bytes, then ran the function hh() on it and if the output was equal to 1725720156 (0x66DC665C) it set solved to true. So our goal was finding a possible input that yielded this return val.

The last part was the hashing function called hh(). This one was a bit more complex as it contained multiple operations. It looped over the vector and can be broken down into the steps:

1. Fetch vector[i]
2. Get index by xoring the byte with the lsb of tmp
3. Shift tmp by one byte to the left
4. Xor tmp with the tale entry at the index

In the end it xord the result with 0xFFFFFFFF and returned it.

I wrote a mockup of it in python that allows us to debug the whole process:

```py

table = [0, 1996959894, 3993919788, 2567524794, 124634137, 1886057615, 3915621685, 2657392035, 249268274, 2044508324, 3772115230, 2547177864, 162941995, 2125561021, 3887607047, 2428444049, 498536548, 1789927666, 4089016648, 2227061214, 450548861, 1843258603, 4107580753, 2211677639, 325883990, 1684777152, 4251122042, 2321926636, 335633487, 1661365465, 4195302755, 2366115317, 997073096, 1281953886, 3579855332, 2724688242, 1006888145, 1258607687, 3524101629, 2768942443, 901097722, 1119000684, 3686517206, 2898065728, 853044451, 1172266101, 3705015759, 2882616665, 651767980, 1373503546, 3369554304, 3218104598, 565507253, 1454621731, 3485111705, 3099436303, 671266974, 1594198024, 3322730930, 2970347812, 795835527, 1483230225, 3244367275, 3060149565, 1994146192, 31158534, 2563907772, 4023717930, 1907459465, 112637215, 2680153253, 3904427059, 2013776290, 251722036, 2517215374, 3775830040, 2137656763, 141376813, 2439277719, 3865271297, 1802195444, 476864866, 2238001368, 4066508878, 1812370925, 453092731, 2181625025, 4111451223, 1706088902, 314042704, 2344532202, 4240017532, 1658658271, 366619977, 2362670323, 4224994405, 1303535960, 984961486, 2747007092, 3569037538, 1256170817, 1037604311, 2765210733, 3554079995, 1131014506, 879679996, 2909243462, 3663771856, 1141124467, 855842277, 2852801631, 3708648649, 1342533948, 654459306, 3188396048, 3373015174, 1466479909, 544179635, 3110523913, 3462522015, 1591671054, 702138776, 2966460450, 3352799412, 1504918807, 783551873, 3082640443, 3233442989, 3988292384, 2596254646, 62317068, 1957810842, 3939845945, 2647816111, 81470997, 1943803523, 3814918930, 2489596804, 225274430, 2053790376, 3826175755, 2466906013, 167816743, 2097651377, 4027552580, 2265490386, 503444072, 1762050814, 4150417245, 2154129355, 426522225, 1852507879, 4275313526, 2312317920, 282753626, 1742555852, 4189708143, 2394877945, 397917763, 1622183637, 3604390888, 2714866558, 953729732, 1340076626, 3518719985, 2797360999, 1068828381, 1219638859, 3624741850, 2936675148, 906185462, 1090812512, 3747672003, 2825379669, 829329135, 1181335161, 3412177804, 3160834842, 628085408, 1382605366, 3423369109, 3138078467, 570562233, 1426400815, 3317316542, 2998733608, 733239954, 1555261956, 3268935591, 3050360625, 752459403, 1541320221, 2607071920, 3965973030, 1969922972, 40735498, 2617837225, 3943577151, 1913087877, 83908371, 2512341634, 3803740692, 2075208622, 213261112, 2463272603, 3855990285, 2094854071, 198958881, 2262029012, 4057260610, 1759359992, 534414190, 2176718541, 4139329115, 1873836001, 414664567, 2282248934, 4279200368, 1711684554, 285281116, 2405801727, 4167216745, 1634467795, 376229701, 2685067896, 3608007406, 1308918612, 956543938, 2808555105, 3495958263, 1231636301, 1047427035, 2932959818, 3654703836, 1088359270, 936918000, 2847714899, 3736837829, 1202900863, 817233897, 3183342108, 3401237130, 1404277552, 615818150, 3134207493, 3453421203, 1423857449, 601450431, 3009837614, 3294710456, 1567103746, 711928724, 3020668471, 3272380065, 1510334235, 755167117]

def split_bytes(value):
    result = []
    while value > 0:
        result.insert(0, value & 0xFF)
        value >>= 8
    return result

def hash(input_string):
    tmp = 0xffffffff

    input_length = len(input_string)
    i = 0;

    while (i < input_length):
        print("Round:" + str(i))
        
        byte_value = input_string[i]
        print("Byte:" + hex(byte_value))

        index = tmp ^ byte_value
        index = index & 0xff

        print("index:" + hex(index))

        tmp = tmp >> 8;

        print("shifted tmp:" + hex(tmp))

        tmp = tmp ^ table[index];

        print("tmp:" + hex(tmp))

        i = i+1;

    return ((tmp ^ 0xffffffff) == 0x66DC665C)


if hash(split_bytes(0x4834434b)):
    print("Solution found!")
```

So we know that the final tmp must be 1725720156 (0x66DC665C) ^ 0xFFFFFFFF. From there one we can use the first byte of tmp to find out the last index. We know that the lsb of the last tmp must be the lsb of the table entry, as the first byte of the tmp before xoring it to the table always is 00. When we have the whole table entry we can xor it to the result to find out the other 3 bytes of the tmp before the shift.


```txt
Result               = 0x66DC665C
final XOR            = 0xffffffff ^ 0x66DC665C 
last tmp             = 0x992399a3 
table[3]             = 0x990951ba //Same LSB
//Now we XOR tmp and the table entry
tmp3                 = 0x002ac819
tmp3 (before shift)  = 0x2ac819XX //XX unknown
```

We have now lost the value of the last byte as this was lost in the shift. Luckily this doesn't matter to us for finding the indexes. So now we move on to the next loop.

```txt
tmp3                = 0x2ac819XX
table[251]          = 0x2a6f2b94
tmp2                = 0x00a732XX
tmp2 (before shift) = 0xa732XXXX
```

We have recovered another index and continue so until we don't have any known values left

```txt
tmp2                = 0xa732XXXX
table[228]          = 0xa732dcb8
tmp1                = 0x0055XXXX
tmp1 (before shift) = 0x55XXXXXX
```

```txt
tmp1                = 0x55XXXXXX
table[183]          = 0x5505262f
tmp0                = 0x00XXXXXX
tmp0 (before shift) = 0xXXXXXXXX
```

So we now wave found the 4 indexes that were used [183, 228, 251,3].

Now we still need to find our bytes. I retrieved these by starting from the begin with a bytevector of length 4 and calculate them in each step. As we know that they are the xor of the last byte of tmp and the index we can now easily calculate them.

```txt
tmp                    = 0xffffffff
byte[0] = 0xB7 ^ 0xFF  = 0x48           //index[0] = 0xB7
shifted_tmp            = 0x00FFFFFF
table[183]             = 0x5505262f
tmp0                   = 0x55fad9d0
byte[1] = 0xE4 ^ 0x60  = 0x34           //index[1] = 0xE4
shifted_tmp0           = 0x0055fad9
table[228]             = 0xa7672661
tmp1                   = 0xa732dcb8
byte[2] = 0xFB ^ 0xb8  = 0x43           //index[2] = 0xFB
shifted_tmp1           = 0x00a732dc
table[251]             = 0x2a6f2b94
tmp2                   = 0x2ac81948
byte[3] = 0x03 ^ 0x48  = 0x4b           //index[3] = 0x03
shifted_tmp2           = 0x002ac819
table[3]               = 0x990951ba
tmp3                   = 0x992399a3
```
This yields us the bytes [0x48, 0x34, 0x43, 0x4b], which if we put it into the function and send to the host using the provided script solves the chal.

```rs
module solution::baby_otter_solution {

    use std::vector;

    use sui::tx_context::TxContext;
    use challenge::baby_otter_challenge;

    public entry fun solve(status: &mut baby_otter_challenge::Status, ctx: &mut TxContext) {
        let password : vector<u8> = vector::empty<u8>();
        vector::push_back(&mut password, 0x48);
        vector::push_back(&mut password, 0x34);
        vector::push_back(&mut password, 0x43);
        vector::push_back(&mut password, 0x4b);
        challenge::baby_otter_challenge::request_ownership(status, password, ctx);
    }
}
```

justCTF{w3lc0me_in_the_l3ague_of_Otter!}