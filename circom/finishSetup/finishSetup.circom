pragma circom 2.0.0;
    // 13 for null
    // 12 for opponent
    // 0,...,11 for rank 
include "../../node_modules/circomlib/circuits/pedersen.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
template point2num() {
    signal input x;
    signal input y;
    signal output out;
    var n = 256;
    component xBits = Num2Bits(n);
    xBits.in <-- x;
    component yBits = Num2Bits(n);
    yBits.in <-- y;
    component resultNum = Bits2Num(n);
    for (var i=0; i<256-8; i++) {
        resultNum.in[i] <-- yBits.out[i];
    }
    for (var j=256-8; j<n; j++) {
        resultNum.in[j] <-- xBits.out[j];
    }
    out <-- resultNum.out;
}

template finishSetup() {
    signal input board[12][5];
    signal input player; // 0 for player 1, 1 for player 2
    signal output board_hash;
    signal output isInvalid;
    signal output test;
    var correct_count[12] = [2,1,1,2,2,2,2,3,3,3,3,1];
    var current_count[12] = [0,0,0,0,0,0,0,0,0,0,0,0];
    // compute hash and check rule
    component hasher = Pedersen(480);
    var index = 0;
    var isInvalid_tmp = 0;

    assert(player==0||player==1);

    for (var i=0;i<12;i++){
        for (var j=0;j<5;j++){
            // check rule
            // log(board[i][j]);
            if ((i==2||i==4||i==7||i==9)&&(j==1||j==3)){ 
                // assert(board[j][i]==13);
                if (board[i][j]!=13){
                    isInvalid_tmp = 1;
                    log(1);
                }
            }
            else if ((i==3||i==8)&&(j==2)){
                // assert(board[j][i]==13);
                if (board[i][j]!=13) {
                    isInvalid_tmp = 1;
                    log(2);
                }
            }else{
                // assert(board[j][i]!=13);
                if (board[i][j]==13) {
                    isInvalid_tmp = 1;
                    log(3);
                }
            }
            if (board[i][j]!=13){
                if(board[i][j]!=12){
                    if(player == 0){
                        if(i>=6){
                            isInvalid_tmp=1;
                            log(4);
                        }
                        //assert(i<6);
                    }else{
                        //assert(i>5);
                        if(i<=5){
                            isInvalid_tmp=1;
                            log(5);
                        }
                    }
                    current_count[board[i][j]]++;
                    if (board[i][j]==0){ // check bomb rule
                        //assert(i != tmp);
                        var tmp = (player == 0)?5:6;
                        if (i == tmp){
                            isInvalid_tmp=1;
                            log(6);
                        }
                    }else if(board[i][j]==10){ // check landmine rule
                        if (player == 0){
                            if(i>1){
                                isInvalid_tmp=1;
                                log(7);
                            }
                            //assert(i <= 1);
                        }else{
                            if(i<10){
                                isInvalid_tmp=1;
                                log(8);
                            }
                            //assert(i >= 10);
                        }
                    }else if (board[i][j]==11){ // check flag rule
                        //assert(j==1||j==3);
                        if(j!=1&&j!=3){
                            isInvalid_tmp=1;
                            log(9);
                        }
                        if (player == 0){
                            //assert(i==0);
                            if(i!=0){
                                isInvalid_tmp=1;
                                log(10);
                            }
                        }else{
                            if(i!=11){
                                isInvalid_tmp=1;
                                log(11);
                            }
                            //assert(i==11);
                        }
                    }
                }
            }
            // compute hash
            for (var w=0; w < 8; w++){
                hasher.in[index+w] <-- (board[i][j] >> w) & 1;
            }
            index=index+8;
        }
    }
    for (var i=0;i<12;i++){
        if(current_count[i]!=correct_count[i]){
            isInvalid_tmp=1;
            log(12);
        }
    }
    assert(isInvalid_tmp==0);
    component p2n = point2num();
    p2n.x <== hasher.out[0];
    p2n.y <== hasher.out[1];
    isInvalid <-- isInvalid_tmp;
    board_hash <== p2n.out;
    test <== 3;
}

component main {public [player]} = finishSetup();