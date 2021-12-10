circom Move.circom --r1cs --wasm --sym --c
node ./Move_js/generate_witness.js ./Move_js/Move.wasm input.json witness.wtns
snarkjs powersoftau new bn128 12 pot12_0000.ptau -v
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v
snarkjs groth16 setup Move.r1cs pot12_final.ptau Move_0000.zkey
snarkjs zkey contribute Move_0000.zkey Move_0001.zkey --name="1st Contributor Name" -v
snarkjs zkey export verificationkey Move_0001.zkey verification_key.json
snarkjs groth16 prove Move_0001.zkey witness.wtns proof.json public.json
snarkjs groth16 verify verification_key.json public.json proof.json