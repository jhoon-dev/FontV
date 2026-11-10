// Run only after the exact source commit has passed Desktop builds.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {createPrivateKey, sign, randomBytes, createHash, X509Certificate} from 'node:crypto';
if (process.platform !== 'darwin') throw Error('macOS is required');
if (process.env.NODE_OPTIONS || process.env.NODE_DEBUG || process.env.NODE_V8_COVERAGE) throw Error('Private runtime required');
const team = 'V6445K474Q', bundle = 'app.toolmoa.fontv', version = '2.0.0';
const build = process.env.FONTV_BUILD_NUMBER || '12';
if (!/^\d+$/.test(build)) throw Error('Invalid build number');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'fontv-mac-sign-'));
fs.chmodSync(temp, 0o700);
const run = (cmd, args, options = {}) => execFileSync(cmd, args, {encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 80 * 1024 * 1024, ...options});
const required = name => { const value = process.env[name]; if (!value) throw Error(`Missing ${name}`); delete process.env[name]; return value; };
const keyId = required('ASC_KEY_ID'), issuer = required('ASC_ISSUER_ID');
const p8 = Buffer.from(required('ASC_KEY_BASE64'), 'base64'), privateKey = createPrivateKey(p8);
function token() {
  const now = Math.floor(Date.now() / 1000);
  const h = Buffer.from(JSON.stringify({alg: 'ES256', kid: keyId, typ: 'JWT'})).toString('base64url');
  const p = Buffer.from(JSON.stringify({iss: issuer, iat: now, exp: now + 300, aud: 'appstoreconnect-v1'})).toString('base64url');
  return `${h}.${p}.${sign('sha256', Buffer.from(`${h}.${p}`), {key: privateKey, dsaEncoding: 'ieee-p1363'}).toString('base64url')}`;
}
async function api(route, method = 'GET', body) {
  const url = new URL(route, 'https://api.appstoreconnect.apple.com');
  if (url.origin !== 'https://api.appstoreconnect.apple.com' || !url.pathname.startsWith('/v1/')) throw Error('Invalid Apple API origin');
  for (let attempt = 0; attempt < 4; attempt++) {
    const response = await fetch(url, {method, redirect: 'error', signal: AbortSignal.timeout(30000), headers: {Authorization: `Bearer ${token()}`, 'Content-Type': 'application/json'}, body: body ? JSON.stringify(body) : undefined});
    if (method === 'GET' && (response.status === 429 || response.status >= 500) && attempt < 3) { await response.text(); await new Promise(resolve => setTimeout(resolve, 2000 * (attempt + 1))); continue; }
    if (!response.ok) throw Error(`Apple API ${method} ${url.pathname}: ${response.status} ${await response.text()}`);
    return response.status === 204 ? {} : response.json();
  }
}
async function all(route) { const rows = []; while (route) { const result = await api(route); rows.push(...result.data); route = result.links?.next; } return rows; }
const apps = await all('/v1/apps?' + new URLSearchParams({'filter[bundleId]': bundle}));
if (apps.length !== 1) throw Error('Font V app mismatch');
const appId = apps[0].id;
async function distribute() {
  const groups = await all(`/v1/apps/${appId}/betaGroups?limit=200`);
  const group = groups.find(value => value.attributes.name === 'ToolMoa Internal' && value.attributes.isInternalGroup);
  if (!group) throw Error('Internal beta group missing');
  for (let attempt = 0; attempt < 50; attempt++) {
    const result = await api('/v1/builds?' + new URLSearchParams({'filter[app]': appId, 'filter[version]': build, include: 'preReleaseVersion', limit: '200'}));
    const candidate = result.data.find(value => result.included?.some(pre => pre.id === value.relationships.preReleaseVersion.data.id && pre.attributes.platform === 'MAC_OS' && pre.attributes.version === version));
    if (candidate && ['INVALID', 'FAILED'].includes(candidate.attributes.processingState)) throw Error('Apple rejected macOS build processing');
    if (candidate?.attributes.processingState === 'VALID') {
      if (candidate.attributes.usesNonExemptEncryption == null) await api(`/v1/builds/${candidate.id}`, 'PATCH', {data: {type: 'builds', id: candidate.id, attributes: {usesNonExemptEncryption: false}}});
      const relation = `/v1/betaGroups/${group.id}/relationships/builds`;
      let linked = (await all(relation + '?limit=200')).some(value => value.id === candidate.id);
      if (!linked && !group.attributes.hasAccessToAllBuilds) { await api(relation, 'POST', {data: [{type: 'builds', id: candidate.id}]}); linked = true; }
      if (group.attributes.hasAccessToAllBuilds) linked = true;
      const state = (await api(`/v1/builds/${candidate.id}/buildBetaDetail`)).data.attributes.internalBuildState;
      if (linked && ['READY_FOR_BETA_TESTING', 'IN_BETA_TESTING'].includes(state)) return {success: true, app: appId, build: candidate.id, version, buildNumber: build, group: group.id, state};
    }
    if (attempt === 49) throw Error('Apple processing timeout; use distribute_only to resume');
    await new Promise(resolve => setTimeout(resolve, 30000));
  }
}
if (process.env.FONTV_DISTRIBUTE_ONLY === 'true') {
  try { console.log(JSON.stringify(await distribute())); } finally { fs.rmSync(temp, {recursive: true, force: true}); }
  process.exit(0);
}
let oldSearch = [], keychainCreated = false, installedProfile;
const keychain = path.join(temp, 'signing.keychain-db');
try {
  // Repeat native verification on the signing host before any upload.
  for (const args of [['pub', 'get'], ['analyze'], ['test'], ['test', 'integration_test/desktop_test.dart', '-d', 'macos']]) console.log(run('flutter', args));
  const certFile = path.join(temp, 'mac-store.p12');
  fs.writeFileSync(certFile, Buffer.from(required('MAC_APP_STORE_CERTIFICATES_P12'), 'base64'), {mode: 0o600});
  const certPassword = required('MAC_APP_STORE_CERTIFICATES_PASSWORD');
  oldSearch = run('security', ['list-keychains', '-d', 'user']).match(/"([^"\n]+)"/g)?.map(value => value.slice(1, -1)) || [];
  const password = randomBytes(32).toString('hex');
  run('security', ['create-keychain', '-p', password, keychain]); keychainCreated = true;
  run('security', ['set-keychain-settings', '-lut', '21600', keychain]);
  run('security', ['unlock-keychain', '-p', password, keychain]);
  run('security', ['import', certFile, '-k', keychain, '-P', certPassword, '-T', '/usr/bin/codesign', '-T', '/usr/bin/productbuild', '-T', '/usr/bin/security']);
  run('security', ['set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', password, keychain]);
  run('security', ['list-keychains', '-d', 'user', '-s', keychain, ...oldSearch]);
  const pem = run('security', ['find-certificate', '-a', '-p', keychain]);
  const imported = [...pem.matchAll(/-----BEGIN CERTIFICATE-----[\s\S]+?-----END CERTIFICATE-----/g)].map(value => new X509Certificate(value[0]));
  const certs = await all('/v1/certificates?limit=200');
  const match = type => certs.find(cert => cert.attributes.certificateType === type && imported.some(value => value.subject.includes(team) && createHash('sha1').update(value.raw).digest('hex') === createHash('sha1').update(Buffer.from(cert.attributes.certificateContent, 'base64')).digest('hex')));
  const appCert = match('MAC_APP_DISTRIBUTION') || match('DISTRIBUTION'), installerCert = match('MAC_INSTALLER_DISTRIBUTION');
  if (!appCert || !installerCert) throw Error('Matching Mac application and installer certificates required');
  const fingerprint = cert => createHash('sha1').update(Buffer.from(cert.attributes.certificateContent, 'base64')).digest('hex').toUpperCase();
  const appIdentity = fingerprint(appCert), installerIdentity = fingerprint(installerCert);
  const bundles = await all('/v1/bundleIds?' + new URLSearchParams({'filter[identifier]': bundle}));
  if (bundles.length !== 1 || !['UNIVERSAL', 'MAC_OS'].includes(bundles[0].attributes.platform)) throw Error('macOS-capable bundle identifier required');
  const profiles = await all('/v1/profiles?limit=200&include=bundleId,certificates');
  let profile = profiles.find(value => value.attributes.profileType === 'MAC_APP_STORE' && value.attributes.profileState === 'ACTIVE' && value.relationships.bundleId?.data?.id === bundles[0].id && value.relationships.certificates?.data?.some(cert => cert.id === appCert.id));
  if (!profile) profile = (await api('/v1/profiles', 'POST', {data: {type: 'profiles', attributes: {name: `Font V macOS ${Date.now()}`, profileType: 'MAC_APP_STORE'}, relationships: {bundleId: {data: {type: 'bundleIds', id: bundles[0].id}}, certificates: {data: [{type: 'certificates', id: appCert.id}]}}}})).data;
  const profileFile = path.join(temp, 'FontV.provisionprofile');
  fs.writeFileSync(profileFile, Buffer.from(profile.attributes.profileContent, 'base64'), {mode: 0o600});
  const decoded = path.join(temp, 'profile.plist');
  fs.writeFileSync(decoded, run('security', ['cms', '-D', '-i', profileFile]), {mode: 0o600});
  const details = JSON.parse(run('python3', ['-c', `import plistlib,json,sys,datetime,hashlib
p=plistlib.load(open(sys.argv[1],'rb'));e=p['Entitlements']
assert p['TeamIdentifier']==[sys.argv[2]] and e['com.apple.application-identifier']==sys.argv[2]+'.'+sys.argv[3]
assert not e.get('get-task-allow') and not p.get('ProvisionedDevices')
assert p['ExpirationDate']>datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
assert sys.argv[4] in [hashlib.sha1(c).hexdigest().upper() for c in p['DeveloperCertificates']]
f=sys.argv[5];a=plistlib.load(open(f,'rb'));a.update({k:v for k,v in e.items() if k in ['com.apple.application-identifier','com.apple.developer.team-identifier']});plistlib.dump(a,open(f,'wb'))
print(json.dumps({'uuid':p['UUID']}))`, decoded, team, bundle, appIdentity, 'macos/Runner/Release.entitlements']));
  const profileDir = path.join(os.homedir(), 'Library/Developer/Xcode/UserData/Provisioning Profiles');
  fs.mkdirSync(profileDir, {recursive: true}); installedProfile = path.join(profileDir, `${details.uuid}.provisionprofile`); fs.copyFileSync(profileFile, installedProfile);
  const project = 'macos/Runner.xcodeproj/project.pbxproj';
  let pbx = fs.readFileSync(project, 'utf8');
  const block = /CODE_SIGN_ENTITLEMENTS = Runner\/Release\.entitlements;[\s\S]*?SWIFT_VERSION = 5\.0;/;
  const found = pbx.match(block); if (!found) throw Error('Runner release signing configuration missing');
  const replacement = found[0].replace('CODE_SIGN_STYLE = Automatic;', `CODE_SIGN_STYLE = Manual;\n DEVELOPMENT_TEAM = ${team};\n CODE_SIGN_IDENTITY = "${appIdentity}";`).replace('PROVISIONING_PROFILE_SPECIFIER = "";', `PROVISIONING_PROFILE_SPECIFIER = "${details.uuid}";`);
  pbx = pbx.replace(block, replacement); fs.writeFileSync(project, pbx);
  console.log(run('flutter', ['build', 'macos', '--release', `--build-number=${build}`]));
  const archive = path.resolve('build/macos/archive/FontV.xcarchive');
  console.log(run('xcodebuild', ['-workspace', 'macos/Runner.xcworkspace', '-scheme', 'Runner', '-configuration', 'Release', '-destination', 'generic/platform=macOS', '-archivePath', archive, 'archive']));
  const app = path.join(archive, 'Products/Applications/Font V.app');
  console.log(run('codesign', ['--verify', '--deep', '--strict', '--verbose=2', app]));
  run('python3', ['-c', `import plistlib,sys,subprocess
p=plistlib.load(open(sys.argv[1]+'/Contents/Info.plist','rb'))
assert p['CFBundleIdentifier']==sys.argv[2] and p['CFBundleVersion']==sys.argv[3]
e=plistlib.loads(subprocess.check_output(['codesign','-d','--entitlements',':-',sys.argv[1]],stderr=subprocess.DEVNULL))
assert e['com.apple.security.app-sandbox'] and e['com.apple.security.files.user-selected.read-write']
assert not e.get('get-task-allow') and not e.get('com.apple.security.get-task-allow')
assert e['com.apple.application-identifier']==sys.argv[4]+'.'+sys.argv[2]
assert __import__('os').path.isfile(sys.argv[1]+'/Contents/embedded.provisionprofile')`, app, bundle, build, team]);
  const exportOptions = path.join(temp, 'export.plist');
  run('python3', ['-c', `import plistlib,sys
plistlib.dump(dict(method='app-store-connect',destination='export',signingStyle='manual',teamID=sys.argv[2],signingCertificate=sys.argv[3],installerSigningCertificate=sys.argv[4],provisioningProfiles={sys.argv[5]:sys.argv[6]},manageAppVersionAndBuildNumber=False,uploadSymbols=False),open(sys.argv[1],'wb'))`, exportOptions, team, appIdentity, installerIdentity, bundle, details.uuid]);
  const exported = path.resolve('build/macos/store-export');
  console.log(run('xcodebuild', ['-exportArchive', '-archivePath', archive, '-exportOptionsPlist', exportOptions, '-exportPath', exported]));
  const packages = fs.readdirSync(exported).filter(value => value.endsWith('.pkg')); if (packages.length !== 1) throw Error('Expected one Mac App Store package');
  const pkg = path.join(exported, packages[0]); console.log(run('pkgutil', ['--check-signature', pkg]));
  const apiDir = path.join(temp, 'api'); fs.mkdirSync(apiDir, {mode: 0o700}); fs.writeFileSync(path.join(apiDir, `AuthKey_${keyId}.p8`), p8, {mode: 0o600});
  const altool = action => console.log(run('xcrun', ['altool', action, '--type', 'macos', '--file', pkg, '--apiKey', keyId, '--apiIssuer', issuer], {env: {...process.env, API_PRIVATE_KEYS_DIR: apiDir}}));
  // Creating a draft platform version does not submit an App Store release.
  const versions = await all(`/v1/apps/${appId}/appStoreVersions?limit=200`);
  if (!versions.some(value => value.attributes.platform === 'MAC_OS')) await api('/v1/appStoreVersions', 'POST', {data: {type: 'appStoreVersions', attributes: {platform: 'MAC_OS', versionString: version, releaseType: 'MANUAL'}, relationships: {app: {data: {type: 'apps', id: appId}}}}});
  altool('--validate-app');
  altool('--upload-app');
  console.log(JSON.stringify(await distribute()));
} catch (error) {
  console.error(error.stdout?.toString() || '', error.stderr?.toString() || ''); throw error;
} finally {
  if (installedProfile) fs.rmSync(installedProfile, {force: true});
  if (keychainCreated) { try { run('security', ['list-keychains', '-d', 'user', '-s', ...oldSearch]); run('security', ['delete-keychain', keychain]); } catch {} }
  fs.rmSync(temp, {recursive: true, force: true});
}
