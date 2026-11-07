// Keep signing/build diagnostics encrypted even in this public repository.
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createCipheriv,randomBytes} from 'node:crypto';
if(process.env.NODE_OPTIONS||process.env.NODE_DEBUG||process.env.NODE_V8_COVERAGE)throw Error('Private runtime required');
const key=Buffer.from(process.env.FONTV_DIAGNOSTICS_KEY||'','base64');delete process.env.FONTV_DIAGNOSTICS_KEY;
if(key.length!==32)throw Error('Diagnostics key missing');
const result=spawnSync(process.execPath,['tool/ios_ci.mjs'],{env:process.env,encoding:null,maxBuffer:100*1024*1024,timeout:65*60*1000});
const output=Buffer.concat([result.stdout||Buffer.alloc(0),result.stderr||Buffer.alloc(0),Buffer.from(result.error?.message||'')]);
const iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',key,iv);
const ciphertext=Buffer.concat([cipher.update(output),cipher.final()]);
fs.mkdirSync('artifacts/ci',{recursive:true});
fs.writeFileSync('artifacts/ci/diagnostics.enc.json',JSON.stringify({iv:iv.toString('base64'),tag:cipher.getAuthTag().toString('base64'),ciphertext:ciphertext.toString('base64')}));
const status=result.status??1;
const details=output.toString('utf8').split(/\r?\n/).filter(l=>l.startsWith('{"success":true,')).map(l=>JSON.parse(l)).at(-1);
fs.writeFileSync('artifacts/ci/status.json',JSON.stringify({status,buildNumber:process.env.FONTV_BUILD_NUMBER,...details}));
console.log(details?`Font V ${details.version} (${details.buildNumber}): ${details.state}`:`Font V CI finished with status ${status}; diagnostics encrypted.`);
process.exitCode=status;
