const dnssd = require('dnssd');

let localName = process.env.LOCALNAME
const args = process.argv.slice(2);
if ( args[0] ) {
  localName = args[0]
}

if ( localName == undefined ) {
  console.error("Local name to resolve in the form name.local is required")
  process.exit(1)
}

process.stderr.write(`Resolving ${localName}`)
dnssd.resolve(`${localName}`, 'A').then((result) => {
  console.log(`${result.answer.address}`)
  return result.answer.address
});
