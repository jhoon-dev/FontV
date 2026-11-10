// Private signing diagnostics use the existing protected Apple environment.
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createCipheriv, randomBytes} from 'node:crypto';
if (process.env.NODE_OPTIONS || process.env.NODE_DEBUG || process.env.NODE_V8_COVERAGE) throw Error('Private runtime required');
const key = Buffer.from(process.env.FONTV_DIAGNOSTICS_KEY || '', 'base64');
delete process.env.FONTV_DIAGNOSTICS_KEY;
if (key.length !== 32) throw Error('Diagnostics key missing');
const result = spawnSync(process.execPath, ['tool/macos_ci.mjs'], {
  env: process.env, encoding: null, maxBuffer: 100 * 1024 * 1024, timeout: 65 * 60 * 1000,
});
const output = Buffer.concat([result.stdout || Buffer.alloc(0), result.stderr || Buffer.alloc(0), Buffer.from(result.error?.message || '')]);
const iv = randomBytes(12), cipher = createCipheriv('aes-256-gcm', key, iv);
const ciphertext = Buffer.concat([cipher.update(output), cipher.final()]);
fs.mkdirSync('artifacts/macos-testflight', {recursive: true});
fs.writeFileSync('artifacts/macos-testflight/diagnostics.enc.json', JSON.stringify({iv: iv.toString('base64'), tag: cipher.getAuthTag().toString('base64'), ciphertext: ciphertext.toString('base64')}));
const details = output.toString('utf8').split(/\r?\n/).filter(line => line.startsWith('{"success":true,')).map(line => JSON.parse(line)).at(-1);
const status = result.status ?? 1;
fs.writeFileSync('artifacts/macos-testflight/status.json', JSON.stringify({status, platform: 'MAC_OS', buildNumber: process.env.FONTV_BUILD_NUMBER, ...details}));
console.log(details ? `Font V macOS ${details.version} (${details.buildNumber}): ${details.state}` : `Font V macOS CI finished with status ${status}; diagnostics encrypted.`);
process.exitCode = status;
