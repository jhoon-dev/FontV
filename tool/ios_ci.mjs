// Runs only inside the existing protected macOS signing environment.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {createPrivateKey, sign, randomBytes, createHash} from 'node:crypto';

if (process.platform !== 'darwin') throw Error('macOS is required');
if (process.env.NODE_OPTIONS || process.env.NODE_DEBUG || process.env.NODE_V8_COVERAGE || process.execArgv.some(v=>v.includes('inspect'))) throw Error('Private runtime required');
const team='V6445K474Q', bundle='app.toolmoa.fontv', version='2.0.0';
const build=process.env.FONTV_BUILD_NUMBER || '10';
const testAds=process.env.FONTV_TEST_ADS || 'true';
if(!['true','false'].includes(testAds))throw Error('Invalid ads mode');
if (!/^\d+$/.test(build)) throw Error('Invalid build number');
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'fontv-sign-'));
fs.chmodSync(temp,0o700);
const run=(cmd,args,options={})=>execFileSync(cmd,args,{encoding:'utf8',stdio:['ignore','pipe','pipe'],maxBuffer:64*1024*1024,...options});
const required=k=>{const v=process.env[k]; if(!v)throw Error(`Missing ${k}`);delete process.env[k];return v;};
const keyId=required('ASC_KEY_ID'), issuer=required('ASC_ISSUER_ID');
const p8=Buffer.from(required('ASC_KEY_BASE64'),'base64');
const privateKey=createPrivateKey(p8);
const token=()=>{const h=Buffer.from(JSON.stringify({alg:'ES256',kid:keyId,typ:'JWT'})).toString('base64url');const now=Math.floor(Date.now()/1000);const p=Buffer.from(JSON.stringify({iss:issuer,iat:now,exp:now+300,aud:'appstoreconnect-v1'})).toString('base64url');return `${h}.${p}.${sign('sha256',Buffer.from(`${h}.${p}`),{key:privateKey,dsaEncoding:'ieee-p1363'}).toString('base64url')}`;};
async function api(route,method='GET',body){
  const u=new URL(route,'https://api.appstoreconnect.apple.com');
  if(u.origin!=='https://api.appstoreconnect.apple.com'||!u.pathname.startsWith('/v1/'))throw Error('Invalid API origin');
  for(let attempt=0;attempt<4;attempt++){
    let res;
    try{res=await fetch(u,{method,redirect:'error',signal:AbortSignal.timeout(30000),headers:{Authorization:`Bearer ${token()}`,'Content-Type':'application/json',Connection:'close'},body:body?JSON.stringify(body):undefined});}
    catch(e){if(method!=='GET'||attempt===3)throw e;await new Promise(r=>setTimeout(r,2000*(attempt+1)));continue;}
    if(method==='GET'&&(res.status===429||res.status>=500)&&attempt<3){await res.text();await new Promise(r=>setTimeout(r,2000*(attempt+1)));continue;}
    if(!res.ok)throw Error(`Apple API ${method} ${u.pathname}: ${res.status} ${await res.text()}`);
    return res.status===204?{}:res.json();
  }
}
async function all(route){const rows=[];while(route){const res=await api(route);rows.push(...res.data);route=res.links?.next;}return rows;}
const pause=ms=>new Promise(r=>setTimeout(r,ms));
async function distribute(){
  const apps=await all('/v1/apps?'+new URLSearchParams({'filter[bundleId]':bundle}));if(apps.length!==1)throw Error('App mismatch');
  const groups=await all(`/v1/apps/${apps[0].id}/betaGroups?limit=200`);
  const group=groups.find(g=>g.attributes.name==='ToolMoa Internal'&&g.attributes.isInternalGroup);if(!group)throw Error('Internal group missing');
  for(let i=0;i<50;i++){
    const res=await api('/v1/builds?'+new URLSearchParams({'filter[app]':apps[0].id,'filter[version]':build,include:'preReleaseVersion',limit:'200'}));
    const b=res.data.find(b=>res.included?.some(p=>p.id===b.relationships.preReleaseVersion.data.id&&p.attributes.version===version&&p.attributes.platform==='IOS'));
    if(b&&['INVALID','FAILED'].includes(b.attributes.processingState))throw Error('Apple processing rejected build');
    if(b?.attributes.processingState==='VALID'){
      const relation=`/v1/betaGroups/${group.id}/relationships/builds`;
      let linked=(await all(relation+'?limit=200')).some(x=>x.id===b.id);
      if(!linked&&!group.attributes.hasAccessToAllBuilds){await api(relation,'POST',{data:[{type:'builds',id:b.id}]});linked=true;}
      const state=(await api(`/v1/builds/${b.id}/buildBetaDetail`)).data.attributes.internalBuildState;
      if(linked&&['READY_FOR_BETA_TESTING','IN_BETA_TESTING'].includes(state))return {success:true,app:apps[0].id,build:b.id,version,buildNumber:build,group:group.id,state};
      if(state==='MISSING_EXPORT_COMPLIANCE')throw Error('Export compliance required');
    }
    if(i===49)throw Error('Apple processing timeout; upload remains available');
    await pause(30000);
  }
}
if(process.env.FONTV_DISTRIBUTE_ONLY==='true'){
  try{console.log(JSON.stringify(await distribute()));}finally{fs.rmSync(temp,{recursive:true,force:true});}
  process.exit(0);
}
let installedProfile, keychainCreated=false, oldSearch=[];
const keychain=path.join(temp,'signing.keychain-db');
try {
  const certFile=path.join(temp,'distribution.p12');
  fs.writeFileSync(certFile,Buffer.from(required('MAS_CSC_LINK'),'base64'),{mode:0o600});
  const certPassword=required('MAS_CSC_KEY_PASSWORD');
  oldSearch=run('security',['list-keychains','-d','user']).match(/"([^"\n]+)"/g)?.map(v=>v.slice(1,-1))||[];
  const password=randomBytes(32).toString('hex');
  run('security',['create-keychain','-p',password,keychain]);keychainCreated=true;
  run('security',['set-keychain-settings','-lut','21600',keychain]);
  run('security',['unlock-keychain','-p',password,keychain]);
  run('security',['import',certFile,'-k',keychain,'-P',certPassword,'-T','/usr/bin/codesign','-T','/usr/bin/security']);
  run('security',['set-key-partition-list','-S','apple-tool:,apple:,codesign:','-s','-k',password,keychain]);
  run('security',['list-keychains','-d','user','-s',keychain,...oldSearch]);
  const identities=run('security',['find-identity','-v','-p','codesigning',keychain]);
  const matches=[...identities.matchAll(/([A-F0-9]{40}) "Apple Distribution: ([^"]+)"/g)].filter(m=>m[2].includes(`(${team})`));
  if(matches.length!==1)throw Error('Exactly one matching Apple Distribution identity required');
  const identity=matches[0][1];
  const bundles=await all('/v1/bundleIds?'+new URLSearchParams({'filter[identifier]':bundle,limit:'200'}));
  if(bundles.length!==1)throw Error('Font V bundle identifier missing');
  const certs=await all('/v1/certificates?limit=200');
  const cert=certs.find(c=>c.attributes.certificateContent&&createHash('sha1').update(Buffer.from(c.attributes.certificateContent,'base64')).digest('hex').toUpperCase()===identity);
  if(!cert)throw Error('Distribution certificate unavailable to API');
  let profiles=await all('/v1/profiles?limit=200&include=bundleId,certificates');
  let profile=profiles.find(p=>p.attributes.profileType==='IOS_APP_STORE'&&p.attributes.profileState==='ACTIVE'&&p.relationships.bundleId?.data?.id===bundles[0].id&&p.relationships.certificates?.data?.some(c=>c.id===cert.id));
  if(!profile)profile=(await api('/v1/profiles','POST',{data:{type:'profiles',attributes:{name:`Font V ToolMoa ${Date.now()}`,profileType:'IOS_APP_STORE'},relationships:{bundleId:{data:{type:'bundleIds',id:bundles[0].id}},certificates:{data:[{type:'certificates',id:cert.id}]}}}})).data;
  const profileFile=path.join(temp,'fontv.mobileprovision');
  fs.writeFileSync(profileFile,Buffer.from(profile.attributes.profileContent,'base64'),{mode:0o600});
  const decoded=run('security',['cms','-D','-i',profileFile]);
  const plistFile=path.join(temp,'profile.plist');fs.writeFileSync(plistFile,decoded,{mode:0o600});
  const details=JSON.parse(run('python3',['-c',`import plistlib,json,sys,hashlib,datetime
p=plistlib.load(open(sys.argv[1],'rb'));e=p['Entitlements']
assert p['TeamIdentifier']==[sys.argv[2]] and e['application-identifier']==sys.argv[2]+'.'+sys.argv[3]
assert not e.get('get-task-allow') and not p.get('ProvisionedDevices')
assert p['ExpirationDate']>datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
assert sys.argv[4] in [hashlib.sha1(c).hexdigest().upper() for c in p['DeveloperCertificates']]
print(json.dumps({'uuid':p['UUID'],'name':p['Name']}))`,plistFile,team,bundle,identity]));
  const profileDir=path.join(os.homedir(),'Library/Developer/Xcode/UserData/Provisioning Profiles');fs.mkdirSync(profileDir,{recursive:true});
  installedProfile=path.join(profileDir,`${details.uuid}.mobileprovision`);fs.copyFileSync(profileFile,installedProfile);
  const project='ios/Runner.xcodeproj/project.pbxproj';
  let pbx=fs.readFileSync(project,'utf8');
  pbx=pbx.replaceAll(`PRODUCT_BUNDLE_IDENTIFIER = ${bundle};`,`PRODUCT_BUNDLE_IDENTIFIER = ${bundle};\n DEVELOPMENT_TEAM = ${team};\n CODE_SIGN_STYLE = Manual;\n CODE_SIGN_IDENTITY = "${identity}";\n PROVISIONING_PROFILE_SPECIFIER = "${details.uuid}";`);
  fs.writeFileSync(project,pbx);
  const exportOptions=path.join(temp,'export.plist');
  run('python3',['-c',`import plistlib,sys
plistlib.dump(dict(method='app-store-connect',destination='export',signingStyle='manual',teamID=sys.argv[2],signingCertificate=sys.argv[3],provisioningProfiles={sys.argv[4]:sys.argv[5]},manageAppVersionAndBuildNumber=False,stripSwiftSymbols=True,uploadSymbols=False),open(sys.argv[1],'wb'))`,exportOptions,team,identity,bundle,details.uuid]);
  console.log('Signing profile ready. Building Font V.');
  for(const [cmd,args] of [['flutter',['pub','get']],['flutter',['analyze']],['flutter',['test']],['flutter',['build','ipa','--release',`--build-name=${version}`,`--build-number=${build}`,`--dart-define=USE_TEST_ADS=${testAds}`,`--export-options-plist=${exportOptions}`]]]){
    try{console.log(run(cmd,args));}catch(e){console.error(e.stdout?.toString(),e.stderr?.toString());throw Error(`${cmd} ${args[0]} failed`);}
  }
  console.log(run('python3',['tool/verify_ios_archive.py',bundle,build]));
  const ipas=fs.readdirSync('build/ios/ipa').filter(f=>f.endsWith('.ipa'));if(ipas.length!==1)throw Error('Expected one IPA');
  const ipa=path.resolve('build/ios/ipa',ipas[0]);
  const apiDir=path.join(temp,'api');fs.mkdirSync(apiDir,{mode:0o700});fs.writeFileSync(path.join(apiDir,`AuthKey_${keyId}.p8`),p8,{mode:0o600});
  for(const action of ['--validate-app','--upload-app']){
    try{console.log(run('xcrun',['altool',action,'--type','ios','--file',ipa,'--apiKey',keyId,'--apiIssuer',issuer],{env:{...process.env,API_PRIVATE_KEYS_DIR:apiDir}}));}catch(e){console.error(e.stdout?.toString(),e.stderr?.toString());throw Error(`Apple ${action} failed`);}
  }
  console.log('Uploaded. Waiting for Apple processing.');
  console.log(JSON.stringify(await distribute()));
} finally {
  if(installedProfile)fs.rmSync(installedProfile,{force:true});
  if(keychainCreated){try{run('security',['list-keychains','-d','user','-s',...oldSearch]);run('security',['delete-keychain',keychain]);}catch{}}
  fs.rmSync(temp,{recursive:true,force:true});
}
