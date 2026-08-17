const wordnet = require('wordnet');
wordnet.lookup('fan', function(err, definitions) {
  if (err) console.error(err);
  console.log(definitions);
});
