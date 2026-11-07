// Decrypt the encrypted diagnostic artifact downloaded from the shared CI.
import fs from 'node:fs';
import {createDecipheriv} from 'node:crypto';
const file=process.argv[2];if(!file)throw Error('Encrypted diagnostics path required');
const key=Buffer.from(fs.readFileSync('.local/ci/source-key.txt','utf8').trim(),'base64');
const e=JSON.parse(fs.readFileSync(file,'utf8'));
const d=createDecipheriv('aes-256-gcm',key,Buffer.from(e.iv,'base64'));
d.setAuthTag(Buffer.from(e.tag,'base64'));
process.stdout.write(Buffer.concat([d.update(Buffer.from(e.ciphertext,'base64')),d.final()]));
