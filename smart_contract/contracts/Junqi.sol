// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./finishSetupVerifier.sol";
import "./moveVerifier.sol";

contract Junqi {
  uint64 constant g = 69;
  uint64 constant p = 999983;

  uint64 last_id = 1;
  uint64 public n_games = 0;
  uint64 n_activegames = 0;



  struct Proof{
      bool wait_player1_proof; // true wait, false not wait
      bool wait_player2_proof; //  
      uint [2] player1_start_square;
      uint [2] player2_start_square;
      uint [2] player1_end_square;
      uint [2] player2_end_square;
      //uint8 player1_start_square_rank;
      //uint8 player2_start_square_rank;
      uint player1_end_square_rank;
      uint player2_end_square_rank;
      uint player1_mpc_reuslt;
      uint player2_mpc_result;
  }
  struct Game{
      address p1;
      address p2;
      uint board1_hash;
      uint board2_hash;
      uint64 move_event_id;
      int8 turn; // -1 for p1, 1 for p2
      uint8 wait_attack_move_proof; // 0 for no waiting, 1 for waiting player 1, 2 for waiting player 2
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
  event Win(int8 player, uint gameID);

  mapping(uint => uint) public gameList;
  mapping(uint => Game) public games;
  mapping(uint => Proof) public proofs;

  function declare() external {
    // pseudorandom gameID
    uint64 gameID = (last_id * g) % p;
    while (games[gameID].exists) {
      gameID = (gameID + 1) % p;
    }
    last_id = gameID;
    
    Game storage game = games[gameID];
    //Proof storage proof = proofs[gameID];

    game.p1 = msg.sender;
    game.board1_hash = 0;
    game.p1_finish_setup = false;
    game.turn = -1;
    game.active = false;
    game.exists = true;
    game.finish_setup = false;
    //game.wait_rankString=0;
    game.move_event_id = 0;

    gameList[n_games] = gameID;
    n_games++;
    

    emit GameIDs(msg.sender, gameID);
    emit Join(0, gameID);
  }
  function join(uint gameID) external {
    Game storage game = games[gameID];
    require(game.exists && !game.active);
    require(msg.sender!=game.p1);
    game.p2 = msg.sender;
    game.board2_hash = 0;
    game.p2_finish_setup = false;

    game.active = true;
    n_activegames++;

    emit Join(1, gameID);
  }
  function finishSetup (uint gameID,uint[2] memory a,uint[2][2] memory b,uint[2] memory c,uint[4] memory input) external {
    Game storage game = games[gameID];
    Proof storage proof = proofs[gameID];
    require(game.exists && game.active&&!game.finish_setup);
    if(msg.sender == game.p1){ 
     require(game.p1_finish_setup!=true);
     
     FinishSetupVerifier verifier = new FinishSetupVerifier();
     require(verifier.verifyProof(a, b, c, input)==true);
     
     game.p1_finish_setup = true;
     game.board1_hash = input[0];
     
     emit FinishSetup(0,gameID);
    
    }else if (msg.sender == game.p2){
     require(game.p2_finish_setup!=true);
     
     FinishSetupVerifier verifier = new FinishSetupVerifier();
     require(verifier.verifyProof(a, b, c, input)==true);
     
     game.p2_finish_setup = true;
     game.board2_hash = input[0];
     
     emit FinishSetup(1,gameID);
    }
    if(game.p1_finish_setup==true&&game.p2_finish_setup==true){
     game.finish_setup = true;
     proof.wait_player1_proof = true;
     proof.wait_player2_proof = true;
     game.wait_attack_move_proof = 0;
    }
  }

  function moveVerifierAndSavePublicSignal(uint player, uint gameID,
    uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[11] memory input) internal returns (bool){
    
    Game storage game = games[gameID];
    Proof storage proof = proofs[gameID];
    if(player == 0){
      // Verify proof
      MoveVerifier verifier = new MoveVerifier();
      // Check whether last_hash is equal to gamestate's hash
      if (input[9]!=game.board1_hash){
        return false;
      } 
      if (verifier.verifyProof(a, b, c, input)!=true){
        return false;
      }
      // Save proof public input and output
      proof.player1_start_square[0] = input[4];
      proof.player1_start_square[1] = input[5];
      proof.player1_end_square[0] = input[6];
      proof.player1_end_square[1] = input[7];
      // proof.player1_start_square_rank = 
      proof.player1_end_square_rank = input[8];
      proof.player1_mpc_reuslt = input[10];
      game.board1_hash = input[0];
      proof.wait_player1_proof = false;
      return true;
    }else{
      // Verify proof
      MoveVerifier verifier = new MoveVerifier();
      // Check whether last_hash is equal to gamestate's hash
      if (input[9]!=game.board2_hash){
        return false;
      }
      if (verifier.verifyProof(a, b, c, input)!=true){
        return false;
      }
      // Save proof public input and output
      proof.player2_start_square[0] = input[4];
      proof.player2_start_square[1] = input[5];
      proof.player2_end_square[0] = input[6];
      proof.player2_end_square[1] = input[7];
      // proof.player2_start_square_rank = 
      proof.player2_end_square_rank = input[8];
      proof.player2_mpc_result = input[10];
      game.board2_hash = input[0];
      proof.wait_player2_proof = false;
      return true;
    }
  }

  function compareTwoProofs(uint gameID) internal returns (bool){
    Game storage game = games[gameID];
    Proof storage proof = proofs[gameID];
    if(
    proof.player1_end_square_rank == proof.player2_end_square_rank&&
    proof.player1_mpc_reuslt == proof.player2_mpc_result&&
    proof.player1_start_square[0] == proof.player2_start_square[0]&&
    proof.player1_start_square[1] == proof.player2_start_square[1]&&
    proof.player1_end_square[0] == proof.player2_end_square[0]&&
    proof.player1_end_square[1] == proof.player2_end_square[1]){
      
    proof.wait_player1_proof = true;
    proof.wait_player2_proof = true;
    game.turn = game.turn * -1;
      
      return true;
    
    }else{
      return false;
    }
  }


  function move (string memory moveString,string memory rankString, uint gameID,
                uint[2] memory a, uint[2][2] memory b,
                uint[2] memory c, uint[11] memory input) external {
    // rank string = -1 => move
    // rank string != -1 => attack
    
    Game storage game = games[gameID];
    Proof storage proof = proofs[gameID];
    require(game.exists && game.active && game.finish_setup);
    
    //require((msg.sender == game.p1&&game.turn==-1)||(msg.sender == game.p2&&game.turn==1));
    if(keccak256(abi.encodePacked(rankString))==keccak256(abi.encodePacked("-1"))){
      // Normal move
      if (msg.sender == game.p1){
        require(moveVerifierAndSavePublicSignal(0, gameID, a, b, c, input)==true);
      }else{
        require(moveVerifierAndSavePublicSignal(1, gameID, a, b, c, input)==true);         
      }
      if(proof.wait_player2_proof==true||proof.wait_player1_proof==true){
        emit Move(moveString,rankString, game.turn, gameID,game.move_event_id);
        game.move_event_id+=1;
      }else{
        require(compareTwoProofs(gameID)==true);
      }
    }else{
      // Attack move
      if (proof.wait_player1_proof==true&&proof.wait_player2_proof==true&&game.wait_attack_move_proof==0){
        emit Move(moveString, rankString, game.turn, gameID,game.move_event_id);
        game.move_event_id+=1;
        game.wait_attack_move_proof = 1;
      }else{
        if(msg.sender == game.p1){
          require(moveVerifierAndSavePublicSignal(0, gameID, a, b, c, input)==true);
          if(input[2]==1){
            emit Win(1,gameID);
          }
        }else{
          require(moveVerifierAndSavePublicSignal(1, gameID, a, b, c, input)==true);
          if(input[2]==1){
            emit Win(0,gameID);
          }
        }
        if (proof.wait_player1_proof == false&& proof.wait_player2_proof == false){
          require(compareTwoProofs(gameID)==true);
          game.wait_attack_move_proof = 0;
        }
      }
    }
  }
}