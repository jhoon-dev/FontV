import fs from 'node:fs';
import path from 'node:path';
const root=process.env.RUNNER_TEMP;if(!root)throw Error('Runner temporary directory required');
const key=path.join(root,'fontv-upload.p12');
if(process.argv.includes('--cleanup')){
  fs.rmSync(key,{force:true});fs.rmSync('android/key.properties',{force:true});
}else{
  const requireValue=name=>{const value=process.env[name];if(!value)throw Error(`Missing ${name}`);return value;};
  fs.writeFileSync(key,Buffer.from(requireValue('ANDROID_KEYSTORE_BASE64'),'base64'),{mode:0o600});
  const escape=value=>value.replaceAll('\\','\\\\').replaceAll('\n','\\n').replaceAll('\r','\\r').replaceAll('=','\\=').replaceAll(':','\\:').replaceAll(' ','\\ ');
  const properties={storeFile:key,storePassword:requireValue('ANDROID_KEYSTORE_PASSWORD'),keyPassword:requireValue('ANDROID_KEY_PASSWORD'),keyAlias:requireValue('ANDROID_KEY_ALIAS')};
  fs.writeFileSync('android/key.properties',Object.entries(properties).map(([k,v])=>`${k}=${escape(v)}`).join('\n')+'\n',{mode:0o600});
  console.log('Temporary Android upload signing configured.');
}
