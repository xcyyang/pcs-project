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
library Pairing_Move {
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
        require(success,"pairing_Move-add-failed");
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
        require (success,"pairing_Move-mul-failed");
    }
    /// @return the result of computing the pairing_Move check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing_Move([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing_Move(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing_Move-lengths-failed");
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
        require(success,"pairing_Move-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing_Move check for two pairs.
    function pairing_MoveProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing_Move(p1, p2);
    }
    /// Convenience method for a pairing_Move check for three pairs.
    function pairing_MoveProd3(
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
        return pairing_Move(p1, p2);
    }
    /// Convenience method for a pairing_Move check for four pairs.
    function pairing_MoveProd4(
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
        return pairing_Move(p1, p2);
    }
}
contract MoveVerifier {
    using Pairing_Move for *;
    struct VerifyingKey {
        Pairing_Move.G1Point alfa1;
        Pairing_Move.G2Point beta2;
        Pairing_Move.G2Point gamma2;
        Pairing_Move.G2Point delta2;
        Pairing_Move.G1Point[] IC;
    }
    struct Proof {
        Pairing_Move.G1Point A;
        Pairing_Move.G2Point B;
        Pairing_Move.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing_Move.G1Point(
            1267469164718154724240889035600388213838334350316363492150793392125066841091,
            20829748685559673191744916924314374330605626025760776058922975754536210984713
        );

        vk.beta2 = Pairing_Move.G2Point(
            [6614845094197444500247923581479088103732411279326964278024908197988985842573,
             19079895990591940178615048327144152147550868681569415868175712316576672728485],
            [2029542906400785932349392425544358124321363373220326417047612559021882932482,
             5978155262337066021283112752838281879884621351164742149375110838051759882648]
        );
        vk.gamma2 = Pairing_Move.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing_Move.G2Point(
            [4647194463152039759770586171737534964753623259669742472403050984099999389375,
             20847927824277012033214260493254242102710870988602646720332890460521282975058],
            [11676254782581297069120302014998922842714243391122331035912839643013892179240,
             5863505568748562526643693972827615478654428908204150194189070277270197060021]
        );
        vk.IC = new Pairing_Move.G1Point[](12);
        
        vk.IC[0] = Pairing_Move.G1Point( 
            9909315554360084959565400888727200043716449692528803048866969032994949883478,
            18971600622155684617763336613107362524382142106499384417819975590921242584486
        );                                      
        
        vk.IC[1] = Pairing_Move.G1Point( 
            47898088849578892388805598307291063174374069845193037083419628275059629809,
            1136290532710189296397225193882652277817360269557834262922532458247818696837
        );                                      
        
        vk.IC[2] = Pairing_Move.G1Point( 
            4226071103755408441011512039105765790642330455709869213542405890369574261507,
            21640413474146227185193433284078636118986821893668397474728883766123054524494
        );                                      
        
        vk.IC[3] = Pairing_Move.G1Point( 
            3011418217152396593379611681419697121441251638066434444838378604516645020479,
            14980722380389666280403933962409439604062908091945948182023074379033849415671
        );                                      
        
        vk.IC[4] = Pairing_Move.G1Point( 
            21225950124242114191865762017891168572286990886809689142931049916540361485157,
            10569603441537197324146028321459060768442203286923896304955284021674546126415
        );                                      
        
        vk.IC[5] = Pairing_Move.G1Point( 
            320331724690183086535289072554869435748525841502039039904436558765046437289,
            10515341076562446195728156164985909294641702192270773709311307443768559664903
        );                                      
        
        vk.IC[6] = Pairing_Move.G1Point( 
            18163454590948383308641936964614132384873949291879071329413932786666782398733,
            16832037272055914517891302203426093844366767130579604916991522712977861006787
        );                                      
        
        vk.IC[7] = Pairing_Move.G1Point( 
            11391201598147190886965898933700991250658483280554854814394866646486564615397,
            2570007224920837006481994661511265685758250597199708498493273302833165690685
        );                                      
        
        vk.IC[8] = Pairing_Move.G1Point( 
            15366146122735885190230286553503680222605097191225119903769485148087970276333,
            19481395972855302237214901529783653507512659623388343253704142474700593299482
        );                                      
        
        vk.IC[9] = Pairing_Move.G1Point( 
            5279740660268318296212516730100348369466953854260088019562333861973137331875,
            21334754403854971202445364085493840692687912457341897728277320343808533779889
        );                                      
        
        vk.IC[10] = Pairing_Move.G1Point( 
            19366238459109462281794407602288680052358795744655017086791943460894405484478,
            17699096369981647437257643138093793322012203111037881548744082995516670380143
        );                                      
        
        vk.IC[11] = Pairing_Move.G1Point( 
            11835171851617732719789521686716034601029442175127607152267187414519651284766,
            16380640977405205021807824135560542307849865031011966943287374743221408313764
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing_Move.G1Point memory vk_x = Pairing_Move.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing_Move.addition(vk_x, Pairing_Move.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing_Move.addition(vk_x, vk.IC[0]);
        if (!Pairing_Move.pairing_MoveProd4(
            Pairing_Move.negate(proof.A), proof.B,
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
            uint[11] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing_Move.G1Point(a[0], a[1]);
        proof.B = Pairing_Move.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing_Move.G1Point(c[0], c[1]);
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
