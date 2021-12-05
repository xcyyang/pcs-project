console.log('DEBUG: running MPC')

const { execFile } = require("child_process");

var path = '/Users/kennyli/Desktop/2021_Fall/2_Practical_Crypto/project/pcs-project/mpc/garbled'
var prog = path + '/client'
var args = ['-e', '-i', '800000', path + '/examples/millionaire.mpcl']

execFile(prog, args, (error, stdout, stderr) => {
    // if (error) {
    //     console.log(`error: ${error.message}`);
    //     return;
    // }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    
    console.log(`stdout: ${stdout}`);
});