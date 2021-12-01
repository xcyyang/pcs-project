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

template onRail(){
    signal input square[2];
    signal output out;
    var i = square[0];
    var j = square[1];
    out <-- (((j==4||j==0)&&0<i&&i<11)||(0<j&&j<4&&(i==1||i==5||i==6||i==10)));
}

template abSub(){ 
    // compute distance
    signal input square1[2];
    signal input square2[2];
    signal output out;
    var x1 = square1[0];
    var x2 = square2[0];
    var y1 = square1[1];
    var y2 = square2[1];
    var i = 0;
    var j = 0;
    if (x1 > x2){
        i = x1 - x2;
    }  else{
        i = x2 - x1;
    }
    if (y1 > y2){
        j = y1 - y2;
    }  else{
        j = y2 - y1;
    }
    out <-- i+j;
}

template findPath(){
    //get connection graph
    signal input board[12][5];
    signal input start[2];
    signal input end[2];
    signal output out;
    var graphTemp[12][12] = [
        [0,0,0,0,0,0,0,0,0,0,0,0],
        [0,0,1,0,0,0,1,0,0,0,0,0],
        [0,1,0,1,0,0,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,1,0,0,0],
        [0,0,0,1,0,1,0,0,0,0,0,0],
        [0,0,0,0,1,0,0,0,0,0,1,0],
        [0,1,0,0,0,0,0,1,0,0,0,0],
        [0,0,0,0,0,0,1,0,1,0,0,0],
        [0,0,0,1,0,0,0,1,0,1,0,0],
        [0,0,0,0,0,0,0,0,1,0,1,0],
        [0,0,0,0,0,1,0,0,0,1,0,0],
        [0,0,0,0,0,0,0,0,0,0,0,0]
    ];
    var line[2][11][2]=[
        [[4,0],[3,0],[2,0],[1,0],[1,1],[1,2],[1,3],[1,4],[2,4],[3,4],[4,4]],
        [[7,0],[8,0],[9,0],[10,0],[10,1],[10,2],[10,3],[10,4],[9,4],[8,4],[7,4]]
    ];
    //in the same line
    var avaliable = 0;
    var through = 1;
    if(start[0]<5&&end[0]<5){
        for(var i=0; i<11; i++){
            if ((line[0][i][0]==start[0] && line[0][i][1]==start[1])||(line[0][i][0]==end[0] && line[0][i][1]==end[1])){
                avaliable = 1;
            }
            if (board[line[0][i][0]][line[0][i][1]]!=13 && avaliable ==1){
                through = 0;
            }
            if ((line[0][i][0]==start[0] && line[0][i][1]==start[1])||(line[0][i][0]==end[0] && line[0][i][1]==end[1]) && avaliable == 1 ){
                avaliable = 0;
            }
        }
        //out <-- through;
    }else if(start[0]>7&&end[0]>7){
        for(var i=0; i<11; i++){
            if ((line[1][i][0]==start[0] && line[1][i][1]==start[1])||(line[1][i][0]==end[0] && line[1][i][1]==end[1])){
                avaliable = 1;
            }
            if (board[line[1][i][0]][line[1][i][1]]!=13 && avaliable ==1){
                through = 0;
            }
            if ((line[1][i][0]==start[0] && line[1][i][1]==start[1])||(line[1][i][0]==end[0] && line[1][i][1]==end[1]) && avaliable == 1 ){
                avaliable = 0;
            }
        }
        //out <-- through;
    }else{
       // not in the same line
       // generate graph
        for(var i=0;i<2;i++){
            for(var j=0;j<5;j++){
                if(board[i+5][j]!=13){
                    if(i+5 == start[0] && j == start[1]){
                        graphTemp[i*5+j+1][0]=0;
                        graphTemp[0][i*5+j+1]=0;
                    }else if(i+5 == end[0] && j == end[1]){
                        graphTemp[i*5+j+1][11]=0;
                        graphTemp[11][i*5+j+1]=0;
                    }else{
                        for (var w=0;w<12;w++){
                            graphTemp[i*5+j+1][w]=0;
                            graphTemp[w][i*5+j+1]=0;
                        }
                    }
                }
            }
        }
        var forward = 1;
        var backward = 1;
        through = 0;
        if(start[0]<5){
            for(var i=0;i<11;i++){
                if (line[0][i][0]==start[0] && line[0][i][1]==start[1]){
                    through = 1;
                }else if (board[line[0][i][0]][line[0][i][1]]!=13){
                    if(through == 0){
                        forward = 0;
                    }else{
                        backward =0;
                    }
                }
            }
            graphTemp[0][1]=forward;
            graphTemp[1][0]=forward;
            graphTemp[0][5]=backward;
            graphTemp[5][0]=backward;
        }else if (start[0]>6){
            for(var i=0;i<11;i++){
                if (line[1][i][0]==start[0] && line[1][i][1]==start[1]){
                    through = 1;
                }else if (board[line[1][i][0]][line[1][i][1]]!=13){
                    if(through == 0){
                        forward = 0;
                    }else{
                        backward =0;
                    }
                }
            }
            graphTemp[0][6]=forward;
            graphTemp[6][0]=forward;
            graphTemp[0][10]=backward;
            graphTemp[10][0]=backward;
        }
            if(end[0]<5){
            for(var i=0;i<11;i++){
                if (line[0][i][0]==end[0] && line[0][i][1]==end[1]){
                    through = 1;
                }else if (board[line[0][i][0]][line[0][i][1]]!=13){
                    if(through == 0){
                        forward = 0;
                    }else{
                        backward =0;
                    }
                }
            }
            graphTemp[11][1]=forward;
            graphTemp[1][11]=forward;
            graphTemp[11][5]=backward;
            graphTemp[5][11]=backward;
        }else if (end[0]>6){
            for(var i=0;i<11;i++){
                if (line[1][i][0]==end[0] && line[1][i][1]==end[1]){
                    through = 1;
                }else if (board[line[1][i][0]][line[1][i][1]]!=13){
                    if(through == 0){
                        forward = 0;
                    }else{
                        backward =0;
                    }
                }
            }
            graphTemp[11][6]=forward;
            graphTemp[6][11]=forward;
            graphTemp[11][10]=backward;
            graphTemp[10][11]=backward;
        }
        //getpath
        for(var i = 0; i < 6; i++){
            for(var j = 1; j < 12; j++){
                if(graphTemp[0][j]==1){
                    for(var w = 0; w < 12; w++){
                        if(graphTemp[j][w]==1){
                            graphTemp[0][w]=1;
                        }
                    }
                }
            }
        }
        through = graphTemp[0][11]; 
    }
    out <-- through;
}


template Move() {
    signal input board[12][5];
    signal input player; // 0 for sender, 1 for reciever
    signal input startsquare[2];
    signal input endsquare[2];
    signal input startrank;
    signal input endrank;
    signal input lastboardhash;
    signal output board_hash;
    signal output isInvalid;
    signal output test;
    var isInvalid_tmp = 0;
    // compute hash and check rule
    var newBoard[12][5];
    for (var i=0;i<12;i++){
        for (var j=0;j<5;j++){
            newBoard[i][j] = board[i][j];
        }
    }
    //
    component hasher = Pedersen(480);
    // compare hash
    var index = 0;
    for (var i=0;i<12;i++){
        for (var j=0;j<5;j++){
            for (var w=0; w < 8; w++){
                hasher.in[index+w] <-- (board[i][j] >> w) & 1;
            }
            index=index+8;
            }
        }
    component p2n1 = point2num();
    p2n1.x <== hasher.out[0];
    p2n1.y <== hasher.out[1];
    if (p2n1.out != lastboardhash){
        isInvalid_tmp = 1;
        log(p2n1.out);
        log(6);
    }
    // ally check
    if (board[endsquare[0]][endsquare[1]]!=12 && board[endsquare[0]][endsquare[1]]!=13){
        isInvalid_tmp = 1;
        log(7);
    }
    
    component onR1 = onRail();
    component onR2 = onRail();
    component getP = findPath();
    component sub = abSub();
    assert(player==0||player==1);
    assert(board[startsquare[0]][startsquare[1]]<10);
    onR1.square[0] <== startsquare[0];
    onR1.square[1] <== startsquare[1];
    onR2.square[0] <== endsquare[0];
    onR2.square[1] <== endsquare[1];
    var x1 = startsquare[0];
    var x2 = endsquare[0];
    var y1 = startsquare[1];
    var y2 = endsquare[1]; 
    
    for (var i=0;i<12;i++){
        for (var j=0;j<5;j++){
            getP.board[i][j] <== board[i][j];
        }
    }
    getP.start[0] <== startsquare[0];
    getP.start[1] <== startsquare[1];
    getP.end[0] <== endsquare[0];
    getP.end[1] <== endsquare[1];

    sub.square1[0] <== startsquare[0];
    sub.square1[1] <== startsquare[1];
    sub.square2[0] <== endsquare[0];
    sub.square2[1] <== endsquare[1];

    if((x1 == 0 || x1 == 11)&&(y1==1||y1==3)|| board[startsquare[0]][startsquare[1]] == 10){
        //in the base or landmine
        isInvalid_tmp = 1;
        log(4);
    }else{
        if (onR1.out && onR2.out){
                // on Rail move
                if (board[startsquare[0]][startsquare[1]] != 9 && x1 != x2 && y1 != y2){
                    //other can not turn
                    isInvalid_tmp = 1;
                    log(5);
                }else{

                    if(getP.out != 1){
                        isInvalid_tmp = 1;
                        log(0);
                    }else{
                        if(board[x1][y1] != 9){
                            // only straight move
                            var tempsquare[2] = [x1, y1];
                            if(x1==x2){
                                if(y1>y2){
                                    tempsquare[1] = tempsquare[1]-1;
                                    while(tempsquare[1]!=y2){
                                        if(board[tempsquare[0]][tempsquare[1]] != 13){
                                            isInvalid_tmp = 1;
                                            log(8);
                                        }
                                        tempsquare[1] = tempsquare[1]-1;
                                    }
                                }else{
                                    tempsquare[1] = tempsquare[1]+1;
                                    while(tempsquare[1]!=y2){
                                        if(board[tempsquare[0]][tempsquare[1]] != 13){
                                            isInvalid_tmp = 1;
                                            log(8);
                                        }
                                        tempsquare[1] = tempsquare[1]+1;
                                    }    
                                }
                            }else{
                                    if(x1>x2){
                                        tempsquare[0] = tempsquare[0]-1;
                                        while(tempsquare[0]!=x2){
                                            if(board[tempsquare[0]][tempsquare[1]] != 13){
                                                isInvalid_tmp = 1;
                                                log(8);
                                            }
                                            tempsquare[0] = tempsquare[0]-1;
                                        }
                                    }else{
                                        tempsquare[0] = tempsquare[0]+1;
                                        while(tempsquare[0]!=x2){
                                            if(board[tempsquare[0]][tempsquare[1]] != 13){
                                                isInvalid_tmp = 1;
                                                log(8);
                                            }
                                            tempsquare[0] = tempsquare[0]+1;
                                        }
                                    }
                            }
                        }
                        if (endrank == 13){
                            // just move
                            newBoard[x2][y2] = board[startsquare[0]][startsquare[1]];
                            newBoard[x1][y1] = 13;
                        }else{
                            // attack
                            if (board[startsquare[0]][startsquare[1]] == 0 || endrank == 0 || endrank == board[startsquare[0]][startsquare[1]]){
                                // bomb or tie
                                newBoard[x2][y2] = 13;
                                newBoard[x1][y1] = 13;
                            }else if (endrank == 10){
                                // step on the landmine 
                                if (board[startsquare[0]][startsquare[1]] == 9){
                                    // remove landmine
                                    newBoard[x2][y2] = board[startsquare[0]][startsquare[1]];
                                    newBoard[x1][y1] = 13;
                                }else{
                                    //boom
                                    newBoard[x2][y2] = 13;
                                    newBoard[x1][y1] = 13;
                                }
                            }else{
                                //battle
                                if(board[startsquare[0]][startsquare[1]] < endrank){
                                    //win
                                    newBoard[x2][y2] = board[startsquare[0]][startsquare[1]];
                                    newBoard[x1][y1] = 13;
                                }else{
                                    //lose
                                    newBoard[x2][y2] = 12;
                                    newBoard[x1][y1] = 13;
                                }
                            }
                        }
                    }
                }


        }else{
                // normal move 
                
                
                var distance = sub.out;
                if (distance > 2 || distance ==0){
                    isInvalid_tmp = 1;
                    log(1);
                }else if (distance == 2){
                    //not straight
                    if (x1 == 0 || x1 == 11 || x2 == 0 || x2 == 11 || (x1 + x2)==11){
                        isInvalid_tmp = 1;
                        log(2);
                    }
                }
               if (endrank == 13){
                            // just move
                            newBoard[x2][y2] = board[startsquare[0]][startsquare[1]];
                            newBoard[x1][y1] = 13;
                        }else{
                            // attack
                            if (board[startsquare[0]][startsquare[1]] == 0 || endrank == 0 || endrank == board[startsquare[0]][startsquare[1]]){
                                // bomb or tie
                                newBoard[x2][y2] = 13;
                                newBoard[x1][y1] = 13;
                            }else if (endrank == 10){
                                // step on the landmine 
                                if (board[startsquare[0]][startsquare[1]] == 9){
                                    // remove landmine
                                    newBoard[x2][y2] = board[startsquare[0]][startsquare[1]];
                                    newBoard[x1][y1] = 13;
                                }else{
                                    //boom
                                    newBoard[x2][y2] = 13;
                                    newBoard[x1][y1] = 13;
                                }
                            }else{
                                //battle
                                if(board[startsquare[0]][startsquare[1]] < endrank){
                                    //win
                                    newBoard[x2][y2] = board[startsquare[0]][startsquare[1]];
                                    newBoard[x1][y1] = 13;
                                }else{
                                    //lose
                                    newBoard[x2][y2] = 12;
                                    newBoard[x1][y1] = 13;
                                }
                            }
                        }
        }
    }
        // compute new hash
    component newhasher = Pedersen(480);
    index = 0;
    for (var i=0;i<12;i++){
        for (var j=0;j<5;j++){
            for (var w=0; w < 8; w++){
                newhasher.in[index+w] <-- (newBoard[i][j] >> w) & 1;
            }
            index=index+8;
            }
        }
  

    assert(isInvalid_tmp==0);
    component p2n = point2num();
    p2n.x <== newhasher.out[0];
    p2n.y <== newhasher.out[1];
    isInvalid <-- isInvalid_tmp;
    board_hash <== p2n.out;
    test <== 3;
}

component main {public [player]} = Move();