# Merkle Airdrop

A Foundry project for distributing ERC-20 tokens via a Merkle-tree airdrop. Eligibility is proven with a Merkle proof, and every claim must be authorized by an EIP-712 signature from the recipient — so a third party (gas payer) can submit the transaction on the recipient's behalf without being able to redirect the tokens.

## Contracts

### `src/MerkleAirdrop.sol`

Holds the airdrop tokens and lets whitelisted accounts claim their allocation.

- Constructed with a `merkleRoot` and the airdrop `IERC20` token; both are immutable.
- `claim(account, amount, merkleProof, v, r, s)` transfers `amount` to `account` when:
  - the account has not already claimed (tracked in `s_hasClaimed`),
  - `(v, r, s)` is a valid EIP-712 signature over the `(account, amount)` claim by `account`, and
  - the Merkle proof verifies the leaf against the stored root.
- Leaves are double-hashed (`keccak256(bytes.concat(keccak256(abi.encode(account, amount))))`) to guard against second-preimage attacks.
- Uses OpenZeppelin `EIP712` (domain `"Merkle Airdrop"`, version `"1.0.0"`), `ECDSA`, `MerkleProof`, and `SafeERC20`.
- Emits `Claimed(account, amount)`.
- View helpers: `getMessageHash(account, amount)`, `getMerkleRoot()`, `getAirdropToken()`.

Custom errors: `MerkleAirdrop__InvalidProof`, `MerkleAirdrop__InvalidSignature`, `MerkleAirdrop__AlreadyClaimed`.

### `src/PrdxToken.sol`

The airdropped token: `PrdxToken` ("Paradox Token", symbol `PRDX`), an OpenZeppelin `ERC20` + `Ownable` with an owner-only `mint(to, amount)`.

## Scripts

- `script/GenerateInput.s.sol` — builds `script/target/input.json` from the hard-coded whitelist (4 addresses, 25e18 each).
- `script/MakeMerkle.s.sol` — reads `input.json`, computes the Merkle root and per-leaf proofs (via the [Murky](https://github.com/dmfxyz/murky) library), and writes `script/target/output.json`.
- `script/DeployMerkleAirdrop.s.sol` — deploys `PrdxToken` and `MerkleAirdrop`, then mints and funds the airdrop with `4 * 25e18` PRDX.
- `script/Interact.s.sol` (`ClaimAirdrop`) — claims on behalf of an address using a precomputed proof and signature, resolving the latest deployment via `foundry-devops`.

## Dependencies

Installed as git submodules under `lib/` (see `.gitmodules`):

- `forge-std`
- `openzeppelin-contracts`
- `murky` — Merkle root/proof generation
- `foundry-devops` — latest-deployment lookup

## Usage

### Build & test

```shell
forge build
forge test
```

### Generate the Merkle tree

```shell
make merkle      # runs GenerateInput then MakeMerkle
# or individually:
make generate    # -> script/target/input.json
make make        # -> script/target/output.json
```

Copy the resulting root into `DeployMerkleAirdrop.s.sol` (and the test) and the proofs into the claim flow.

### Local deployment (Anvil)

```shell
make anvil       # in a separate terminal
make deploy
```

For Sepolia, set `SEPOLIA_RPC_URL`, `PRIVATE_KEY`, and `ETHERSCAN_API_KEY` in a `.env` file, then:

```shell
make deploy ARGS="--network sepolia"
```

### Claiming

The Makefile wires up the full local claim flow against the default Anvil accounts:

```shell
make sign        # signs getMessageHash with the claimer's key
make claim       # submits ClaimAirdrop (gas paid by a second account)
make balance     # checks the claimer's PRDX balance
```

Update `AIRDROP_ADDRESS` / `TOKEN_ADDRESS` in the `Makefile` to match your deployment, and paste the signature produced by `make sign` into `script/Interact.s.sol`.

### zkSync

The Makefile also includes `zkbuild`, `zktest`, `zk-anvil`, and `deploy-zk*` targets for the zkSync toolchain.

## Configuration

`foundry.toml` enables read-write filesystem access (`fs_permissions`) so the merkle scripts can read/write `script/target/*.json`.
