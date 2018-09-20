const spawnSync = require('child_process').spawnSync;
exports.handler = (event, context, callback) => {
  const childObject = spawnSync('./WiltCollector',
   [],
   {});
  var stdout = childObject.stdout.toString('utf8');
  console.log(stdout);
  callback(null, "");
};
