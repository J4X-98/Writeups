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