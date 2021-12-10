import {Game} from './lib/Game.js'
import {Piece} from './lib/Piece.js'

// 13 for null
// 12 for opponent
// 0,...,11 for rank 
function compressBoard(playerColor,boardState){
  const m = 12;
  let compressBoard = [];
  for (let i = 0; i < m; i++) {
    compressBoard.push([]);
    compressBoard[i] = [13,13,13,13,13]; // make each element an array
  }
  console.log(compressBoard);
  let i = 0;
  let j = 11;
  for (let sq in boardState){
    if(i==5){
      i = 0;
      j--;
    }
    //console.log(sq);
    let piece = boardState[sq];
    if(piece){
      compressBoard[j][i] = (piece.colorChar == playerColor[0])?parseInt(piece.rankStr,10):12;
    }
    i++;
    // var pieceStr = (piece == null) ? null : (piece.colorChar + piece.rankStr)
  }
  console.log(JSON.stringify(compressBoard));
  return compressBoard;
}
// function decompressBoard(){

//   return boardState;
// }

var Client = (function(window) {
    var game = null;
    
    var socket      = null;
    var web3 = null;
    var JunqiContract = null;
    var currentAccount = null;
    var boardHash = null; 

    var expectedMoveEventID = null;
    var waitOpponentsRank = false;

    var gameState   = null;

    var gameID      = null;
    var playerColor = null;
    var playerName  = null;

    var container   = null;
    var messages    = null;
    var board       = null;
    var squares     = null;

    var gameClasses = null;

    var selection   = null;

    var prevSelectedSquare = null;
    var curSelectedSquare = null;
    var swapStr = null;

    var setupButton = null;
    var gameOverMessage     = null;
    var forfeitPrompt       = null;
    /**
    * Initialize the UI
    */
    async function getMoveProof(moveString, isNormalMove, isSender, mpcResult){
      const startSquareString = moveString.split(" ")[0];
      const endSquareString = moveString.split(" ")[2];
      console.log(startSquareString);
      console.log(endSquareString);
    
      const board = (compressBoard(playerColor,game.board.boardState));
      const senderOrReceiver = (isSender==1)?0:1;
      const startSquare = [parseInt(startSquareString.substring(1),10)-1,startSquareString[0].charCodeAt(0)-'a'.charCodeAt(0)];
      const endSquare = [parseInt(endSquareString.substring(1),10)-1,endSquareString[0].charCodeAt(0)-'a'.charCodeAt(0)];
      console.log(startSquare);
      console.log(endSquare);
      const endRank = (isNormalMove==1)?13:12;
      const mpc_result = mpcResult;
      const lastBoardHash = boardHash;
      var proofAndPublicSignals = null;
      proofAndPublicSignals =  await $.ajax({
        type: 'POST',
        url: '/zksnark/move',
        data: JSON.stringify({board,senderOrReceiver,
        startSquare,endSquare,endRank,mpc_result,lastBoardHash}),
        success: function(result) { 
        },
        contentType: "application/json",
        dataType: 'json'
      });
      console.log((proofAndPublicSignals));
      return proofAndPublicSignals;
    }
    async function getMPCResult(moveString,isEvaluator){
      if(isEvaluator==1){
        const startSquare = moveString.split(" x ")[0];
        let piece = game.board.getPieceAtSquare(startSquare);
        const startRank = piece.rankStr;
        try {
          const mpcResult =  await $.ajax({
            type: 'POST',
            url: '/mpc/evaluator',
            data: JSON.stringify({startRank}),
            success: function(result) { 
            },
            contentType: "application/json"
            //dataType: 'json'
          });
          console.log(mpcResult.charAt(mpcResult.length-2));
          return mpcResult.charAt(mpcResult.length-2);  
        } catch (error) {
          console.log(error);
        }
      }else{
        const endSquare = moveString.split(" x ")[1];
        let piece = game.board.getPieceAtSquare(endSquare);
        const endRank = piece.rankStr;
        try {
          const mpcResult =  await $.ajax({
            type: 'POST',
            url: '/mpc/garbler',
            data: JSON.stringify({endRank}),
            success: function(result) { 
            },
            contentType: "application/json"
            //dataType: 'json'
          });
          console.log(mpcResult.charAt(mpcResult.length-2));
          return mpcResult.charAt(mpcResult.length-2);  
        } catch (error) {
          console.log(error);
        }
      }
    }

    var init = async function(config)
    {   
        gameID      = config.gameID;
        playerColor = config.playerColor;
        playerName  = config.playerName;
        
        web3 = config.web3;
        JunqiContract = config.JunqiContract;
        currentAccount = config.currentAccount;

        container   = $('#game');
        messages    = $('#messages');
        board       = $('#board');

        generateBoardCSS(board);

        squares     = board.find('.square');
        setupButton = $('#finishSetup');

        gameOverMessage     = $('#game-over');
        forfeitPrompt       = $('#forfeit-game');

        gameClasses = "red blue rank0 rank1 rank2 rank3 rank4 rank5 rank6 rank7 rank8 rank9 rank10 rank11 not-moved empty selected " +
                      "valid-move valid-attack valid-swap last-move";

        // Define board based on player's perspective
        assignSquares();

        // Attach event handlers
        attachDOMEventHandlers();
        //attachSocketEventHandlers();

        // Initialize modal popup windows
        gameOverMessage.modal({show: false, keyboard: false, backdrop: 'static'});
        forfeitPrompt.modal({show: false, keyboard: false, backdrop: 'static'});

        // Join game
        // Create a default game board
        var params = {playerColor: playerColor};
        game = new Game (params);
        
        // Update UI
        gameState = game;
        update();

        // Add subscribe
        JunqiContract.events.Join({filter:{gameID: gameID},fromBlock:0},function(error, event){
          if(event!=null&&event['returnValues']['gameID']==gameID){
            console.log(event);
            //console.log(event);
            let playerColor_tmp = event['returnValues']['index']=='0'? 'blue':'red';
            console.log("add player");
            console.log(playerColor_tmp);
            game.addPlayer({playerColor:playerColor_tmp});
            gameState = game;
            update();
          }
        });

        JunqiContract.events.FinishSetup({filter:{gameID: gameID},fromBlock:0},function(error, event){
          if(event!=null&&event['returnValues']['gameID']==gameID){
            console.log(event);
            let playerColor_tmp = event['returnValues']['index']=='0'? 'blue':'red';
            console.log("finish setup");
            console.log(playerColor_tmp);
            game.finishSetup({playerColor:playerColor_tmp});
            gameState=game;
            update();
          } 
        });

        JunqiContract.events.Win({filter:{gameID: gameID},fromBlock:0},function(error, event){
          if(event!=null&&event['returnValues']['gameID']==gameID){
            console.log(event);
            let winnerColor = event['returnValues']['player']=='0'? 'blue':'red';
            console.log("win");
            game.status = 'checkmate';
            _.each(game.players, function(p) {
              console.log(p);
              p.inCheck = p.color==winnerColor?false:true;
            }, this);
            gameState=game;
            update();
          } 
        });

        expectedMoveEventID = 0;
        JunqiContract.events.Move({filter:{gameID: gameID},fromBlock:"latest"},async function(error, event){
          if(event!=null&&event['returnValues']['gameID']==gameID&&event['returnValues']['id']==expectedMoveEventID){
            console.log(event);
            expectedMoveEventID+=1;
            let currentPlayer = (playerColor=='blue')?"-1":"1";
            let isMyself = (currentPlayer==event['returnValues']['turn'])?true:false;
            if(event['returnValues']['rankString']=="-1"){
              console.log(isMyself)
              if(!isMyself){
                const proofAndPublicSignals = await getMoveProof(event['returnValues']['moveString'],1,0,1);
                boardHash = proofAndPublicSignals[4];
                await JunqiContract.methods.move(event['returnValues']['moveString']
                  , "-1"
                  , gameID
                  , proofAndPublicSignals[0], proofAndPublicSignals[1], proofAndPublicSignals[2], proofAndPublicSignals[3]).send({from: currentAccount});
              }
              game.move(event['returnValues']['moveString'],isMyself,0);
              gameState=game;
              console.log(gameState);
              update();
            }else{
              if(!isMyself){
                // TODO 
                // Send rank through MPC to sender
                const mpcResult = await getMPCResult(event['returnValues']['moveString'],0);
                // Receive result of MPC
                const proofAndPublicSignals = await getMoveProof(event['returnValues']['moveString'],0,0,parseInt(mpcResult,10));
                // Send proof to Smart Contract 
                boardHash = proofAndPublicSignals[4];
                await JunqiContract.methods.move(event['returnValues']['moveString']
                  , "12"
                  , gameID
                  , proofAndPublicSignals[0], proofAndPublicSignals[1], proofAndPublicSignals[2], proofAndPublicSignals[3]).send({from: currentAccount});
                // Update UI (need to modify, in order to receive mpc_result）
                game.move(event['returnValues']['moveString'],isMyself, parseInt(mpcResult,10));
                gameState=game;
                update();
              }else{
                // TODO
                // Execute eveluator of MPC
                const mpcResult = await getMPCResult(event['returnValues']['moveString'],1);
                // Receive result of MPC
                const proofAndPublicSignals = await getMoveProof(event['returnValues']['moveString'],0,1,parseInt(mpcResult,10));
                // Send proof to Smart Contract
                boardHash = proofAndPublicSignals[4];
                await JunqiContract.methods.move(event['returnValues']['moveString']
                  , "12"
                  , gameID
                  , proofAndPublicSignals[0], proofAndPublicSignals[1], proofAndPublicSignals[2], proofAndPublicSignals[3]).send({from: currentAccount});
                // Update UI (need to modify, in order to receive mpc_result )
                game.move(event['returnValues']['moveString'],isMyself, parseInt(mpcResult,10));
                gameState=game;
                update();
              }
            }
          } 
        });
    };

    var generateBoardCSS = function(board) {
      // Dynamically create board because most of the rows and columns are the same

      // Top row border
      var topRow = "";
      topRow += "<tr>";
      topRow += "<td class='top-left-corner'></td>";
      for (var col = 1; col <= 5; col++) {
        topRow += "<td class='top-edge'></td>";
      }
      topRow += "<td class='top-right-corner'></td>";
      topRow += "</tr>";
      board.append(topRow);

      // Create a new row to display pieces
      for (var row = 1; row <= 12; row++) {
        var curRow = "";
        curRow += "<tr>";
        curRow += "<td class='left-edge'></td>";
        for (var col = 1; col <= 5; col++) {
          curRow += "<td class='square'></td>";
        }
        curRow += "<td class='right-edge'></td>";
        curRow += "</tr>";
        board.append(curRow);
      }

      // Bottom row border
      var bottomRow = "<tr>";
      bottomRow += "<td class='bottom-left-corner'></td>";
      for (var col = 1; col <= 5; col++) {
        bottomRow += "<td class='bottom-edge'></td>";
      }
      bottomRow += "<td class='bottom-right-corner'></td>";
      bottomRow += "</tr>";
      board.append(bottomRow);
    }

    /**
    * Assign square IDs and labels based on player's perspective
    */
    var assignSquares = function()
    {
        var fileLabels = ['A', 'B', 'C', 'D', 'E'];
        var rankLabels = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
        var squareIDs  = [
            'a12', 'b12', 'c12', 'd12', 'e12',
            'a11', 'b11', 'c11', 'd11', 'e11',
            'a10', 'b10', 'c10', 'd10', 'e10',
            'a9', 'b9', 'c9', 'd9', 'e9',
            'a8', 'b8', 'c8', 'd8', 'e8',
            'a7', 'b7', 'c7', 'd7', 'e7',
            'a6', 'b6', 'c6', 'd6', 'e6',
            'a5', 'b5', 'c5', 'd5', 'e5',
            'a4', 'b4', 'c4', 'd4', 'e4',
            'a3', 'b3', 'c3', 'd3', 'e3',
            'a2', 'b2', 'c2', 'd2', 'e2',
            'a1', 'b1', 'c1', 'd1', 'e1'
        ];

        if (playerColor === 'red')
        {
            fileLabels.reverse();
            rankLabels.reverse();
            squareIDs.reverse();
        }

        // Set file and rank labels
       /* $('.top-edge').each(function(i) { $(this).text(fileLabels[i]); });
        $('.right-edge').each(function(i) { $(this).text(rankLabels[i]); });
        $('.bottom-edge').each(function(i) { $(this).text(fileLabels[i]); });
        $('.left-edge').each(function(i) { $(this).text(rankLabels[i]); });*/

        // Set square IDs
        squares.each(function(i) { $(this).attr('id', squareIDs[i]); });
    };

    var callbackHighlightSwap = function(color, rank)
    {
        return function(ev) {
            //for setup, swap pieces
            for (var i = 0; i < gameState.players.length; i++)
            {
                if (gameState.players[i].color === playerColor && gameState.players[i].isSetup === false)
                {
                    highlightValidSwap(color + rank, ev.target);
                }
            }
        }
    }

    var callbackHighlightMoves = function(color, rank)
    {
        return function(ev) {
            //Show moves for player
            if (gameState.activePlayer && gameState.activePlayer.color === playerColor)
            {
                highlightValidMoves(color + rank, ev.target);
            }
        }
    };

  /**
   * Attach DOM event handlers
   */
  var attachDOMEventHandlers = function()
  {
    // Highlight valid moves for red pieces
    if (playerColor === 'red')
    {
        var baseString = '.red.rank';
        for (var i = 0; i <= 11; i++)
        {
            container.on('click', baseString + i.toString(), callbackHighlightSwap('r', i.toString()));
        }

        for (var i = 0; i < 10; i++)
        {
            container.on('click', baseString + i.toString(), callbackHighlightMoves('r', i.toString()));
        }
    }

    // Highlight valid moves for blue pieces
    if (playerColor === 'blue')
    {
        var baseString = '.blue.rank';
        for (var i = 0; i <= 11; i++)
        {
            container.on('click', baseString + i.toString(), callbackHighlightSwap('b', i.toString()));
        }

        for (var i = 0; i < 10; i++)
        {
            container.on('click', baseString + i.toString(), callbackHighlightMoves('b', i.toString()));
        }
    }
    // Clear all move highlights
    container.on('click', '.empty', function(ev) {
      clearHighlights();
    });

    // Perform a regular move
    container.on('click', '.valid-move', async function(ev) {
        let moveStringAndRankString = generateMoveString(ev.target, '-');
        // Send move message to Ethereum
        console.log(moveStringAndRankString);
        const proofAndPublicSignals = await getMoveProof(moveStringAndRankString.moveString,1,1,1);
        const a = proofAndPublicSignals[0];
        const b = proofAndPublicSignals[1];
        const c = proofAndPublicSignals[2];
        const input = proofAndPublicSignals[3];

        boardHash = proofAndPublicSignals[4];

        await JunqiContract.methods.move(moveStringAndRankString.moveString
                                  , "-1"
                                  , gameID
                                  , a, b, c, input).send({from: currentAccount});
    });

    // Attack the opponent's piece
    container.on('click', '.valid-attack', function(ev) {
        let moveStringAndRankString = generateMoveString(ev.target, 'x');
        
        // Send move message to Ethereum
        console.log(moveStringAndRankString);

        JunqiContract.methods.move(moveStringAndRankString.moveString
                                   , moveStringAndRankString.rankString
                                  , gameID
                                  , ["0x0","0x0"]
                                  ,[["0x0","0x0"],["0x0","0x0"]]
                                  , ["0x0","0x0"]
                                  ,["0x0","0x0","0x0","0x0","0x0","0x0","0x0","0x0","0x0","0x0","0x0"])
                                  .send({from: currentAccount});

    });

    //Swap pieces
    container.on('click', '.valid-swap', function(ev) {
        var m = swapStr;

        messages.empty();
        var data = {gameID: gameID, move: m}
        var result = game.move(data.move,true,0);
        gameState = game;
        update();
        //socket.emit('move', {gameID: gameID, move: m});
    });

    //Finish setup
      container.on('click', '#finishSetup', async function(ev) {
           //socket.emit('finishSetup', gameID);
           //Finish setup
           //var result = game.finishSetup({playerColor: playerColor});
           // Send msg to Ethereum
           const board = (compressBoard(playerColor,game.board.boardState));
           const player = (playerColor=='blue')?0:1;
           console.log(board);
           console.log(player);
           var proofAndPublicSignals = null
           proofAndPublicSignals =  await $.ajax({
            type: 'POST',
            url: '/zksnark/finishSetup',
            data: JSON.stringify({board,player}), // or JSON.stringify ({name: 'jonas'}),
            success: function(result) { 
              //console.log('proof: ' + $.parseJSON(result));
              //proofAndPublicSignals = $.parseJSON(result);
            },
            contentType: "application/json",
            dataType: 'json'
          });
            console.log((proofAndPublicSignals));
            const a = proofAndPublicSignals[0];
            const b = proofAndPublicSignals[1];
            const c = proofAndPublicSignals[2];
            const input = proofAndPublicSignals[3];
            // console.log(proofAndPublicSignals.publicSignals);
            console.log(a);
            console.log(b);
            console.log(c);
            console.log(input);
            boardHash = proofAndPublicSignals[4];
            console.log(boardHash);
            JunqiContract.methods.finishSetup(gameID,a,b,c,input).send({from: currentAccount});
      });


    // Forfeit game
    container.on('click', '#forfeit', function(ev) {
        // showForfeitPrompt(function(confirmed) {
        //     if (confirmed)
        //     {
        //       messages.empty();
        //       socket.emit('forfeit', gameID);
        //     }
        // });

        });
    };

    var generateMoveString = function(destinationSquare, symbol)
    {
        var piece = selection.pieceStr;
        var src   = $('#'+selection.squareId);
        var dest  = $(destinationSquare);

        clearHighlights();

        var pieceClass = getPieceClasses(piece);

        // Move piece on board
        src.removeClass(pieceClass).addClass('empty');
        dest.removeClass('empty').addClass(pieceClass);

        // Return move string
        let moveString = selection.squareId + ' ' + symbol + ' ' + dest.attr('id');
        return {moveString:moveString, rankString: getPieceRank(piece)};
    }

    /**
    * Attach Socket.IO event handlers
    */
    // var attachSocketEventHandlers = function()
    // {
    //     // Update UI with new game state
    //     socket.on('update', function(data) {
    //         //console.log(data);
    //         gameState = data;
    //         console.log(gameState);
    //         update();
    //     });

    //     // Display an error
    //     socket.on('error', function(data) {
    //         //console.log(data);
    //         showErrorMessage(data);
    //     });
    // };

    var highlightValidSwap = function(piece, selectedSquare)
    {
        var square = $(selectedSquare);
        var move   = null;

        // Set selection object
        selection = {
            pieceStr: piece,
            squareId:  square.attr('id'),
        };

        // Highlight the selected square
        squares.removeClass('selected');
        square.addClass('selected');

        curSelectedSquare = square.attr('id');
        swapStr = curSelectedSquare + ' ' + 's' + ' ' + prevSelectedSquare;

        // Highlight any valid moves
        squares.removeClass('valid-swap');
        for (var i = 0; i < gameState.validSwap.length; i++)
        {
            move = gameState.validSwap[i];

            if (move.type === 'swap')
            {
                if (move.startSquare === square.attr('id'))
                {
                    prevSelectedSquare = square.attr('id');
                    $('#'+move.endSquare).addClass('valid-swap');
                }
            }
        }
    }

    /**
    * Highlight valid moves for the selected piece
    */
    var highlightValidMoves = function(piece, selectedSquare)
    {
        var square = $(selectedSquare);
        var move   = null;

        // Set selection object
        selection = {
            pieceStr: piece,
            squareId:  square.attr('id'),
        };

        // Highlight the selected square
        squares.removeClass('selected');
        square.addClass('selected');

        // Highlight any valid moves
        squares.removeClass('valid-move valid-attack');
        for (var i=0; i<gameState.validMoves.length; i++)
        {
            move = gameState.validMoves[i];

            if (move.type === 'move')
            {
                // Highlight empty squares to move to
                if (move.startSquare === square.attr('id'))
                {
                    $('#'+move.endSquare).addClass('valid-move');
                }
            }
            else if (move.type === 'attack')
            {
                // Highlight squares with enemy pieces
                if (move.startSquare === square.attr('id'))
                {
                    $('#'+move.endSquare).addClass('valid-attack');
                }
            }
        }
    };

    /**
    * Clear valid move highlights
    */
    var clearHighlights = function()
    {
        squares.removeClass('selected');
        squares.removeClass('valid-move');
        squares.removeClass('valid-attack');
        squares.removeClass('valid-swap');
    };

  /**
   * Update UI from game state
   */
  var update = function() {   
    console.log(gameState);
    var you, opponent = null;
    var container, name, status, captures = null;

    // Update player info
    for (var i = 0; i < gameState.players.length; i++)
    {
        // Determine if player is you or opponent
        if (gameState.players[i].color === playerColor)
        {
          you = gameState.players[i];
          container = $('#you');
        }
        else if (gameState.players[i].color !== playerColor)
        {
          opponent = gameState.players[i];
          container = $('#opponent');
        }

        name     = container.find('strong');
        status   = container.find('.status');
        captures = container.find('ul');

        // Name
        if (gameState.players[i].name)
        {
            //if the player quits midgame, don't show any name
            if (gameState.players[i].joined === false)
            {
                name.text("...");
                gameState.players[i].name = null;
            }
            else
            {
                name.text(gameState.players[i].name);
            }
        }

        // Active Status
        container.removeClass('active-player');
        if (gameState.activePlayer && gameState.activePlayer.color === gameState.players[i].color)
        {
          container.addClass('active-player');
        }

        //Setup Status
        container.removeClass('setup-player ready-player');
        if (gameState.players[i].isSetup === false)
        {
            container.addClass('setup-player');
        }
        else if (gameState.players[i].isSetup === true && gameState.status === 'pending')
        {
            container.addClass('ready-player');
        }

      // Check Status
      /*status.removeClass('label label-danger').text('');
      if (gameState.players[i].inCheck) {
        status.addClass('label label-danger').text('Check');
      }*/

      // Captured Pieces
      /*captures.empty();
      for (var j=0; j<gameState.capturedPieces.length; j++) {
        if (gameState.capturedPieces[j][0] !== gameState.players[i].color[0]) {
          captures.append('<li class="'+getPieceClasses(gameState.capturedPieces[j])+'"></li>');
        }
      }*/
    }
   
    // Update board
    for (var sq in gameState.board.boardState)
    {
      var piece = gameState.board.boardState[sq];
      var pieceStr = (piece == null) ? null : (piece.colorChar + piece.rankStr)
      var pieceClass = getPieceClasses(pieceStr);
      $('#'+sq).removeClass(gameClasses).addClass(pieceClass);
    }

    // Highlight last move
    if (gameState.lastMove)
    {
        if (gameState.lastMove.type === 'move' || gameState.lastMove.type === 'attack')
        {
            $('#'+gameState.lastMove.startSquare).addClass('last-move');
            $('#'+gameState.lastMove.endSquare).addClass('last-move');
        }
    }

    // Test for checkmate
    if (gameState.status === 'checkmate')
    {
        if (opponent.inCheck) { showGameOverMessage('checkmate-win');  }
        if (you.inCheck)      { showGameOverMessage('checkmate-lose'); }
    }

    // Test for stalemate
    if (gameState.status === 'nopieces')
    {
        if (opponent.hasMoveablePieces === false) { showGameOverMessage('nopieces-win'); }
        if (you.hasMoveablePieces === false) { showGameOverMessage('nopieces-lose'); }
    }

    // Test for forfeit
    if (gameState.status === 'forfeit')
    {
        if (opponent.forfeited) { showGameOverMessage('forfeit-win');  }
        if (you.forfeited)      { showGameOverMessage('forfeit-lose'); }
    }
  };

  /**
   * Display an error message on the page
   */
  var showErrorMessage = function(data) {
    var msg, html = '';

    if (data == 'handshake unauthorized') {
      msg = 'Client connection failed';
    } else {
      msg = data.message;
    }

    html = '<div class="alert alert-danger">'+msg+'</div>';
    messages.append(html);
  };

  /**
   * Display the "Game Over" window
   */
  var showGameOverMessage = function(type) {
        var header = gameOverMessage.find('h2');

        // Set the header's content and CSS classes
        header.removeClass('alert-success alert-danger alert-warning');
        switch (type) {
            case 'checkmate-win'  : header.addClass('alert-success').text('Captured Flag'); break;
            case 'checkmate-lose' : header.addClass('alert-danger').text('Flag Lost'); break;
            case 'forfeit-win'    : header.addClass('alert-success').text('Your opponent has surrendered'); break;
            case 'forfeit-lose'   : header.addClass('alert-danger').text('You have surrendered'); break;
            case 'nopieces-win'  : header.addClass('alert-success').text('Your opponent has no moveable pieces'); break;
            case 'nopieces-lose' : header.addClass('alert-danger').text('You have no moveable pieces left'); break;
        }
        gameOverMessage.modal('show');
  };

  /**
   * Display the "Forfeit Game" confirmation prompt
   */
  var showForfeitPrompt = function(callback) {
        // Temporarily attach click handler for the Cancel button, note the use of .one()
        forfeitPrompt.one('click', '#cancel-forfeit', function(ev) {
            callback(false);
            forfeitPrompt.modal('hide');
        });

        // Temporarily attach click handler for the Confirm button, note the use of .one()
        forfeitPrompt.one('click', '#confirm-forfeit', function(ev) {
            callback(true);
            forfeitPrompt.modal('hide');
        });

        forfeitPrompt.modal('show');
  };

  /**
   * Get the corresponding CSS classes for a given piece
   */
  var getPieceClasses = function(piece) {
      if (piece == null) {
          return 'empty';
      }
      var pieceColor = piece[0];
      var className = '';
      var pieceRank = getPieceRank(piece);
      //console.log(sq);
      //Don't reveal any of your opponent's pieces (the only exception is the flag which can be revealed after the commander dies)
      if (playerColor[0] !== pieceColor)
      {
          //Check to make sure pieces are setup
          //If your opponent's pieces aren't setup, don't display anything
          if (isPieceInOpponentSetup(pieceColor, playerColor)) {
            return '';
          }

          //Display flag when commander dies
          if (shouldRevealOpponentFlag(pieceColor, pieceRank, playerColor)) {
            //Determine the opponent's color (if you're blue, the opponent must be red)
            if (playerColor[0] === 'r')
            {
                return 'blue rank11';
            }
            else if (playerColor[0] === 'b')
            {
                return 'red rank11';
            }
          }

          //Never display any other piece's rank
          if (playerColor[0] !== 'b'&&pieceRank=="-1")
          {
              return 'facedown blue';
          }
          else if (playerColor[0] !== 'r'&&pieceRank=="-1")
          {
              return 'facedown red';
          }
      }

      if (pieceColor === 'b')
      {
          className += 'blue ';
      }
      else if (pieceColor === 'r')
      {
          className += 'red ';
      }

      className += 'rank' + pieceRank;

      if (piece[piece.length - 1] === '_')
      {
         className += ' not-moved';
      }

      return className;
  };

  // currentPieceColor is "r" or "b"
  // playerColor can be "red" or "blue"
  var isPieceInOpponentSetup = function(currentPieceColor, playerColor) {
    // If player owns that piece, it should not be shown
    if (playerColor[0] === currentPieceColor) {
      return false;
    }

    // Find the owner of that piece
    var indexOwner = -1;
    for (var i = 0; i < gameState.players.length; i++) {
      if (gameState.players[i].color[0] === currentPieceColor) {
        indexOwner = i;
        break;
      }
    }

    // The piece doesn't have an owner
    // Should not reach this point
    if (indexOwner == -1) {
      return false;
    }

    // The other player is not finished seting up the game
    return gameState.players[indexOwner].isSetup === false
  }

  // currentPieceColor is "r" or "b"
  // playerColor can be "red" or "blue"
  var shouldRevealOpponentFlag = function(currentPieceColor, pieceRank, playerColor) {
    const RANK_FLAG = "11";

    // If player owns that piece, it will already be revealed
    if (playerColor[0] === currentPieceColor) {
      return false;
    }

    // If this piece is not the flag, it should not be revealed
    if (pieceRank !== RANK_FLAG) {
      return false;
    }

    // Find the owner of that piece
    var indexOwner = -1;
    for (var i = 0; i < gameState.players.length; i++) {
      if (gameState.players[i].color[0] === currentPieceColor) {
        indexOwner = i;
        break;
      }
    }

    if (indexOwner == -1) {
      return false;
    }

    // Reveal the flag if that player lost its commander.
    return gameState.players[indexOwner].hasCommander === false;
  }

    var getPieceRank = function(piece)
    {   
        var lengthRank = null;
        if (piece[piece.length - 1] === '_')
        {
            lengthRank = piece.length - 2;
        }
        else
        {
            lengthRank = piece.length - 1;
        }

        return piece.substr(1, lengthRank);
    };

  return init;

}(window));
export {Client};
