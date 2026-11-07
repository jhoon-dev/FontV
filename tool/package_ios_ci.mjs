// Creates a source envelope for the shared public CI; the key stays local/protected.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {randomBytes,createCipheriv,createHash} from 'node:crypto';
const destination=process.argv[2];if(!destination)throw Error('Destination required');
fs.mkdirSync('.local/ci',{recursive:true});
const keyFile='.local/ci/source-key.txt';
if(!fs.existsSync(keyFile))fs.writeFileSync(keyFile,randomBytes(32).toString('base64'),{mode:0o600});
const key=Buffer.from(fs.readFileSync(keyFile,'utf8').trim(),'base64');
const commit=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
const archive=execFileSync('git',['archive','--format=zip','HEAD'],{maxBuffer:16*1024*1024});
const metadata={schema:1,sourceCommit:commit,archiveSha256:createHash('sha256').update(archive).digest('hex')};
const iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',key,iv);cipher.setAAD(Buffer.from(JSON.stringify(metadata)));
const ciphertext=Buffer.concat([cipher.update(archive),cipher.final()]);
fs.mkdirSync(path.dirname(destination),{recursive:true});
fs.writeFileSync(destination,JSON.stringify({...metadata,iv:iv.toString('base64'),tag:cipher.getAuthTag().toString('base64'),ciphertext:ciphertext.toString('base64')})+'\n');
console.log(JSON.stringify(metadata));
