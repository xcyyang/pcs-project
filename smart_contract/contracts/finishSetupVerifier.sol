//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;
library Pairing_FinishSetup {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing_FinishSetup-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing_FinishSetup-mul-failed");
    }
    /// @return the result of computing the pairing_FinishSetup check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing_FinishSetup([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing_FinishSetup(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing_FinishSetup-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing_FinishSetup-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing_FinishSetup check for two pairs.
    function pairing_FinishSetupProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing_FinishSetup(p1, p2);
    }
    /// Convenience method for a pairing_FinishSetup check for three pairs.
    function pairing_FinishSetupProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing_FinishSetup(p1, p2);
    }
    /// Convenience method for a pairing_FinishSetup check for four pairs.
    function pairing_FinishSetupProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing_FinishSetup(p1, p2);
    }
}
contract FinishSetupVerifier {
    using Pairing_FinishSetup for *;
    struct VerifyingKey {
        Pairing_FinishSetup.G1Point alfa1;
        Pairing_FinishSetup.G2Point beta2;
        Pairing_FinishSetup.G2Point gamma2;
        Pairing_FinishSetup.G2Point delta2;
        Pairing_FinishSetup.G1Point[] IC;
    }
    struct Proof {
        Pairing_FinishSetup.G1Point A;
        Pairing_FinishSetup.G2Point B;
        Pairing_FinishSetup.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing_FinishSetup.G1Point(
            1267469164718154724240889035600388213838334350316363492150793392125066841091,
            20829748685559673191744916924314374330605626025760776058922975754536210984713
        );

        vk.beta2 = Pairing_FinishSetup.G2Point(
            [6614845094197444500247923581479088103732411279326964278024908197988985842573,
             19079895990591940178615048327144152147550868681569415868175712316576672728485],
            [2029542906400785932349392425544358124321363373220326417047612559021882932482,
             5978155262337066021283112752838281879884621351164742149375110838051759882648]
        );
        vk.gamma2 = Pairing_FinishSetup.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing_FinishSetup.G2Point(
            [2546860922849842690381739638775178544805589344234033083032642471335472294640,
             1881091022179931848222378849983992749627575025296352857247821225948356015265],
            [17032754936033339729207695911704176130497141355976910714568190709368516452344,
             21346882558802898631290750089231992973662242981485940344731074621978012699682]
        );
        vk.IC = new Pairing_FinishSetup.G1Point[](5);
        
        vk.IC[0] = Pairing_FinishSetup.G1Point( 
            7823812727862755563123524021246329569843919591207943958931318395605483016222,
            4283519138178437586508817158346485303702644091187458818871455136966635495645
        );                                      
        
        vk.IC[1] = Pairing_FinishSetup.G1Point( 
            8952636777492027961834050904153564450263358591297499781305388603304582009537,
            19399029100843261163913073900615041428772029877097500064356039435272732401525
        );                                      
        
        vk.IC[2] = Pairing_FinishSetup.G1Point( 
            3722362738194593486099469555897124931496392203388820095871392760367497960229,
            18149249177019167635588848700860096885070917175859594270620809620116618577789
        );                                      
        
        vk.IC[3] = Pairing_FinishSetup.G1Point( 
            20367963432867761050152767335847322493304272094927987719481019239752273036412,
            5482094063434447927557155234087126084185330652443518190666837680959857365684
        );                                      
        
        vk.IC[4] = Pairing_FinishSetup.G1Point( 
            3274506261719952780339040550036574270697316238337144123154127401844460103696,
            7040625525826753378503156788727852010799668253046942769579610159806974810681
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing_FinishSetup.G1Point memory vk_x = Pairing_FinishSetup.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing_FinishSetup.addition(vk_x, Pairing_FinishSetup.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing_FinishSetup.addition(vk_x, vk.IC[0]);
        if (!Pairing_FinishSetup.pairing_FinishSetupProd4(
            Pairing_FinishSetup.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[4] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing_FinishSetup.G1Point(a[0], a[1]);
        proof.B = Pairing_FinishSetup.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing_FinishSetup.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
