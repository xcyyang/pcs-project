// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract Junqi {
  uint64 constant g = 69;
  uint64 constant p = 999983;

  uint64 last_id = 1;
  uint64 public n_games = 0;
  uint64 n_activegames = 0;

  struct Game{
      address p1;
      address p2;
      int8 [5][12] board;
      uint64 board1_hash;
      uint64 board2_hash;
      uint64 move_event_id;
      int8 turn; // -1 for p1, 1 for p2
      uint8 wait_rankString; // 0 for no waiting, 1 for waiting player 1, 2 for waiting player 2
      bool active; // two players ready
      bool p1_finish_setup;
      bool p2_finish_setup;
      bool finish_setup;
      bool exists;
  }

  event Join(uint index, uint gameID); // index: 0 for player1, 1 for player2

  event FinishSetup(uint index, uint gameID); // index: 0 for player1, 1 for player2

  event GameIDs(address indexed from, uint gameID);
  event Move(string moveString,string rankString, int8 turn, uint gameID, uint64 id);


  mapping(uint => uint) public gameList;
  mapping(uint => Game) public games;

  function declare() external {
    // pseudorandom gameID
    uint64 gameID = (last_id * g) % p;
    while (games[gameID].exists) {
      gameID = (gameID + 1) % p;
    }
    last_id = gameID;
    
    Game storage game = games[gameID];

    game.p1 = msg.sender;
    game.board1_hash = 0;
    game.p1_finish_setup = false;
    game.turn = -1;
    game.active = false;
    game.exists = true;
    game.finish_setup = false;
    game.wait_rankString=0;
    game.move_event_id = 0;

    gameList[n_games] = gameID;
    n_games++;
    

    emit GameIDs(msg.sender, gameID);
    emit Join(0, gameID);
  }
  function join(uint gameID) external {
    Game storage game = games[gameID];
    require(game.exists && !game.active);

    game.p2 = msg.sender;
    game.board2_hash = 0;
    game.p2_finish_setup = false;

    game.active = true;
    n_activegames++;

    // init the board
    // -1 for hide player1
    // -2 for hide player2
    // 0,...,11 for player1
    // 12,...,23 for player2
    int8 tmp = -1;
    for (uint8 i = 0; i<12 ; i++){
       if(i>5){tmp=-2;}  
       for (uint8 j = 0; j<5; j++){
         if((i==2||i==4||i==7||i==9)&&(j==1||j==3)){
           continue;
         }
         if((i==3||i==8)&&(j==2)){
           continue;
         }
         game.board[i][j]=tmp;
       }
     }
    // Emit event
    emit Join(1, gameID);
  }
  function finishSetup (uint gameID) external {
    Game storage game = games[gameID];
    require(game.exists && game.active&&!game.finish_setup);
    if(msg.sender == game.p1){
     require(game.p1_finish_setup!=true);
     game.p1_finish_setup = true;
     emit FinishSetup(0,gameID);
    }else if (msg.sender == game.p2){
     require(game.p2_finish_setup!=true);
     game.p2_finish_setup = true;
     emit FinishSetup(1,gameID);
    }
    if(game.p1_finish_setup==true&&game.p2_finish_setup==true){
     game.finish_setup = true;
     //emit FinishSetup(2,gameID);
    }
  }
  function move (string memory moveString,string memory rankString, uint gameID) external {
    // rank string = -1 => move
    // rank string != -1 => attack
    Game storage game = games[gameID];
    require(game.exists && game.active && game.finish_setup);
    if(game.wait_rankString==0){
      require((msg.sender == game.p1&&game.turn==-1)||(msg.sender == game.p2&&game.turn==1));
      if(keccak256(abi.encodePacked(rankString))==keccak256(abi.encodePacked("-1"))){
        //normal
        emit Move(moveString,rankString, game.turn, gameID,game.move_event_id);
        game.move_event_id+=1;
        game.turn = game.turn * -1;
      }else{
        //attack
        emit Move(moveString, rankString, game.turn, gameID,game.move_event_id);
        game.move_event_id+=1;
        game.wait_rankString=(msg.sender==game.p1)?2:1;
      }
    }else{
      if(game.wait_rankString==1){
        require(msg.sender == game.p1);
        emit Move(moveString, rankString, -1, gameID,game.move_event_id);
        game.move_event_id+=1;
        game.wait_rankString=0;
        game.turn = game.turn * -1;
      }else if (game.wait_rankString==2){
        require(msg.sender == game.p2);
        emit Move(moveString, rankString, 1, gameID,game.move_event_id);
        game.move_event_id+=1;
        game.wait_rankString=0;
        game.turn = game.turn * -1;
      }
    }
  }
  function checkGameEnd() internal{

  }
}