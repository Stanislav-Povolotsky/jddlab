// jddlab smoke-test fixture: a tiny React-Native-like bundle compiled to Hermes
// bytecode (tests/fixtures/index.android.bundle). Rebuild with:
//   npm pack hermes-compiler@0.17.0 && tar xzf hermes-compiler-*.tgz
//   package/hermesc/linux64-bin/hermesc -emit-binary -O -out index.android.bundle index.android.js
var JDDLAB_API_ENDPOINT = "https://api.jddlab.example/v1/login";
function jddlabCheckLicense(key) {
  if (key === "JDDLAB-SECRET-KEY-1234") {
    return "license-ok";
  }
  return "license-bad";
}
print(jddlabCheckLicense("test") + " " + JDDLAB_API_ENDPOINT);
