{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

# dsh boots through node-addon-require-builtin, which locates Node's internal
# require by decoding the machine code of PrincipalRealm::builtin_module_require()
# and accepts only a bare `mov off(%rdi),%rax; ret`. nixpkgs builds Node with
# the zerocallusedregs hardening flag, which adds `xor %edi,%edi` before every
# ret, so the addon rejects nixpkgs Node. The official build keeps the bare form.
let
  version = "24.20.0";
  platforms = {
    x86_64-linux = { arch = "linux-x64"; hash = "sha256-LywNoWIxjw3kdmVBDHyMLtPTbI8xBd5LvGEXbHCny/I="; };
    aarch64-linux = { arch = "linux-arm64"; hash = "sha256-X03athDBqyAWs8Inzr2/bZSVFhSH5HOce5AJBZX0Zfc="; };
    x86_64-darwin = { arch = "darwin-x64"; hash = "sha256-JvwwiRAEYD0JTu0R3l780Du9LvvDXBd/xyZI1dencBs="; };
    aarch64-darwin = { arch = "darwin-arm64"; hash = "sha256-t793BwcLlQuh7F8a87tt4PKxlixQM5c9lAaKsCHvMBQ="; };
  };
  platform = platforms.${stdenv.hostPlatform.system}
    or (throw "node-bin: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "nodejs-bin";
  inherit version;

  src = fetchurl {
    url = "https://nodejs.org/dist/v${version}/node-v${version}-${platform.arch}.tar.xz";
    inherit (platform) hash;
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  # The dsh wrapper only runs node itself, so npm and the headers stay out.
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/node $out/bin/node
    runHook postInstall
  '';

  meta = {
    description = "Official Node.js ${version} binary from nodejs.org";
    homepage = "https://nodejs.org";
    license = lib.licenses.mit;
    platforms = lib.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "node";
  };
}
