//var DB = null;
var path = require('path');
const snarkjs = require('snarkjs')
const fs = require('fs')


function unstringifyBigInts(o) {
  if (typeof o == "string" && /^[0-9]+$/.test(o)) {
    return BigInt(o);
  } else if (Array.isArray(o)) {
    return o.map(unstringifyBigInts);
  } else if (typeof o == "object") {
    const res = {};
    const keys = Object.keys(o);
    keys.forEach(k => {
      res[k] = unstringifyBigInts(o[k]);
    });
    return res;
  } else {
    return o;
  }
}
/**
 * Validate session data for "Game" page
 * Returns valid data on success or null on failure
 */
// var validateGame = function(req) {

//   // These must exist
//   if (!req.session.gameID)      { return null; }
//   if (!req.session.playerColor) { return null; }
//   if (!req.session.playerName)  { return null; }
//   if (!req.params.id)           { return null; }

//   // These must match
//   if (req.session.gameID !== req.params.id) { return null; }

//   return {
//     gameID      : req.session.gameID,
//     playerColor : req.session.playerColor,
//     playerName  : req.session.playerName
//   };
// };

/**
 * Validate "Start Game" form input
 * Returns valid data on success or null on failure
 */
// var validateStartGame = function(req) {

//   // These must exist
//   if (!req.body['player-color']) { return null; }

//   // Player Color must be 'red' or 'blue'
//   if (req.body['player-color'] !== 'red' && req.body['player-color'] !== 'blue') { return null; }

//   // If Player Name consists only of whitespace, set as 'Player 1'
//   if (/^\s*$/.test(req.body['player-name'])) { req.body['player-name'] = 'Player 1'; }

//   return {
//     playerColor : req.body['player-color'],
//     playerName  : req.body['player-name']
//   };
// };

/**
 * Validate "Join Game" form input
 * Returns valid data on success or null on failure
 */
// var validateJoinGame = function(req) {

//     console.log(req.body['game-id']);
    
//   // These must exist
//   if (!req.body['game-id']) { return null; }

//   // If Game ID consists of only whitespace, return null
//   if (/^\s*$/.test(req.body['game-id'])) { return null; }

//   // If Player Name consists only of whitespace, set as 'Player 2'
//   if (/^\s*$/.test(req.body['player-name'])) { req.body['player-name'] = 'Player 2'; }

//   return {
//     gameID      : req.body['game-id'],
//     playerName  : req.body['player-name']
//   };
// };

/**
 * Render "Home" Page
 */
var home = function(req, res) {

  //var listIDs = DB.list();
  // TODO retrieve game list
    
  // Welcome
  res.render('home');
};

/**
 * Render "Game" Page (or redirect to home page if session is invalid)
 */
var game = function(req, res) {
  const gameID = req.params['id'];
  const playerColor = req.query['playerColor'];
  const playerName = req.query['playerName'];
  console.log(gameID);
  console.log(playerColor);
  console.log(playerName);
  // req.session.playerName = "Anonymous";
  // Validate session data
  // var validData = validateGame(req);
  // if (!validData) { res.redirect('/'); return; }
  // Render the game page
  res.render('game', {
    gameID: gameID,
    playerColor: playerColor,
    playerName: playerName
  });
};

/**
 * Process "Start Game" form submission
 * Redirects to game page on success or home page on failure
 */
// var startGame = function(req, res) {
//   // Create a new session
//   // req.session.regenerate(function(err) {
//   //   if (err) { res.redirect('/'); return; }

//   //   // Validate form input
//   //   // var validData = validateStartGame(req);
//   //   // if (!validData) { res.redirect('/'); return; }

//   //   // Create new game
//   //   //var gameID = DB.add(validData);
//   //   var gameID = "test"
//   //   // Save data to session
//   //   // req.session.gameID      = gameID;
//   //   // req.session.playerColor = validData.playerColor;
//   //   // req.session.playerName  = validData.playerName;

//   //   // Redirect to game page
//   //   res.redirect('/game/'+"test");
//   // });
//   res.redirect('/game/'+"test");
// };

/**
 * Process "Join Game" form submission
 * Redirects to game page on success or home page on failure
 */
// var joinGame = function(req, res) {

//   // Create a new session
//   req.session.regenerate(function(err) {
//     if (err) { res.redirect('/'); return; }
      
//     // Validate form input
//     var validData = validateJoinGame(req);
//     if (!validData) { res.redirect('/'); return; }

//     // Find specified game
//     var game = DB.find(validData.gameID);
//     if (!game) { res.redirect('/'); return;}

//     // Determine which player (color) to join as
//     var joinColor = (game.players[0].joined) ? game.players[1].color : game.players[0].color;

//     // Save data to session
//     req.session.gameID      = validData.gameID;
//     req.session.playerColor = joinColor;
//     req.session.playerName  = validData.playerName;

//     // Redirect to game page
//     res.redirect('/game/'+validData.gameID);
//   });
// };

/**
 * Redirect non-existent routes to the home page
 */
var invalid = function(req, res) {

  // Go home HTTP request, you're drunk
  res.redirect('/');
};

/**
 * Attach route handlers to the app
 */
exports.attach = function(app, db) {
  //DB = db;

  app.get('/',         home);
  app.get('/game/:id', game);
  // app.post('/start',   startGame);
  // app.post('/join',    joinGame);
  app.post('/zksnark/move', async function (req,res){
    const board = req.body.board; // [5][12]
    const senderOrReceiver = req.body.senderOrReceiver; // 0 for sender, 1 for receiver
    const startSquare = req.body.startSquare; // [2]
    const endSquare = req.body.endSquare; // [2]
    const startRank = req.body.startRank; // int
    const endRank = req.body.endRank; // int 
    const lastBoardHash = req.body.lastBoardHash;   // BigInt


    const wc = require('../circom/move/Move_js/witness_calculator');
    const wasm = path.resolve('./circom/move/Move_js/Move.wasm');
    const zkey = path.resolve('./circom/move/circuit_final.zkey');
    //const INPUTS_FILE = '/tmp/inputs';
    const WITNESS_FILE = '/tmp/witness';

    const generateWitness = async (inputs) => {
      const buffer = fs.readFileSync(wasm);
      const witnessCalculator = await wc(buffer);
      const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
      fs.writeFileSync(WITNESS_FILE, buff);
    }
    try {
      console.log(typeof(board));
      console.log(typeof(player));
      const inputSignals = { board: board 
        , player: senderOrReceiver
        , startSquare: startSquare
        , endSquare: endSquare
        , startRank: startRank
        , endRank: endRank
        , lastBoardHash: lastBoardHash} // replace with your signals
      await generateWitness(inputSignals)
      const { proof, publicSignals } = await snarkjs.groth16.prove(zkey, WITNESS_FILE);  
      console.log(proof);
      console.log(publicSignals);
      
      const calls = await snarkjs.groth16.exportSolidityCallData(unstringifyBigInts(proof),unstringifyBigInts(publicSignals));
      console.log(calls);
      var args = JSON.parse("[" + calls + "]");
      console.log(args);
      args.push(publicSignals[0]);
      res.status(200).send(args);
    } catch (error) {
      console.log(error);
      res.status(500).json(error);      
    }
  });


  app.post('/zksnark/finishSetup', async function (req, res){
    const board = req.body.board;
    const player = req.body.player;

    const wc = require('../circom/finishSetup/finishSetup_js/witness_calculator');
    const wasm = path.resolve('./circom/finishSetup/finishSetup_js/finishSetup.wasm');
    const zkey = path.resolve('./circom/finishSetup/circuit_final.zkey');
    //const INPUTS_FILE = '/tmp/inputs';
    const WITNESS_FILE = '/tmp/witness';

    const generateWitness = async (inputs) => {
      const buffer = fs.readFileSync(wasm);
      const witnessCalculator = await wc(buffer);
      const buff = await witnessCalculator.calculateWTNSBin(inputs, 0);
      fs.writeFileSync(WITNESS_FILE, buff);
    }
    try {
      console.log(typeof(board));
      console.log(typeof(player));
      const inputSignals = { board: board 
        , player: player} // replace with your signals
      await generateWitness(inputSignals)
      const { proof, publicSignals } = await snarkjs.groth16.prove(zkey, WITNESS_FILE);  
      console.log(proof);
      console.log(publicSignals);
      
      const calls = await snarkjs.groth16.exportSolidityCallData(unstringifyBigInts(proof),unstringifyBigInts(publicSignals));
      console.log(calls);
      let args = JSON.parse("[" + calls + "]");
      console.log(args);
      args.push(publicSignals[0]);
      res.status(200).send(args);
    } catch (error) {
      console.log(error);
      res.status(500).json(error);      
    }
  });
  app.all('*',invalid);
  
};
