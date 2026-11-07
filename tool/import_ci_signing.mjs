// Import the authorized encrypted migration envelope without plaintext files/logs.
import fs from 'node:fs';
import {createDecipheriv} from 'node:crypto';
import {execFileSync} from 'node:child_process';
const file=process.argv[2];if(!file)throw Error('Encrypted transfer path required');
const e=JSON.parse(fs.readFileSync(file,'utf8'));
const names=['MAS_CSC_LINK','MAS_CSC_KEY_PASSWORD','ASC_KEY_BASE64','ASC_KEY_ID','ASC_ISSUER_ID'];
if(e.schema!==1||e.destination!=='jhoon-dev/fontv'||e.environment!=='apple-testflight'||JSON.stringify(e.names)!==JSON.stringify(names))throw Error('Unexpected signing transfer destination');
const metadata={schema:e.schema,destination:e.destination,environment:e.environment,names:e.names};
const key=Buffer.from(fs.readFileSync('.local/ci/source-key.txt','utf8').trim(),'base64');
const d=createDecipheriv('aes-256-gcm',key,Buffer.from(e.iv,'base64'));d.setAAD(Buffer.from(JSON.stringify(metadata)));d.setAuthTag(Buffer.from(e.tag,'base64'));
const plaintext=Buffer.concat([d.update(Buffer.from(e.ciphertext,'base64')),d.final()]);
const values=JSON.parse(plaintext.toString('utf8'));plaintext.fill(0);
for(const name of names){
  if(typeof values[name]!=='string'||!values[name])throw Error(`Missing ${name}`);
  try{execFileSync(process.platform==='win32'?'C:/Program Files/GitHub CLI/gh.exe':'gh',['secret','set',name,'--repo',e.destination,'--env',e.environment],{input:values[name],stdio:['pipe','pipe','pipe']});}
  catch{throw Error(`Could not store ${name}; no secret values were logged`);}
  delete values[name];console.log(`Stored ${name} in protected Font V environment.`);
}
