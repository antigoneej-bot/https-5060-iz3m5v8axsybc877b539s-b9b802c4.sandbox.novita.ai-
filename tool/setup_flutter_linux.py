"""Install the tested SDK versions in a user-writable folder (Linux x64)."""
import argparse
import hashlib
import os
from pathlib import Path
import subprocess
import shutil
import tarfile
import urllib.request
import zipfile

FLUTTER_VERSION = "3.35.7"
FLUTTER_SHA256 = "146df531f9ac6a11a918013c1a70faafc053d4811c8cb69a413fd70748d51c3d"
JDK_URL = 'https://aka.ms/download-jdk/microsoft-jdk-17.0.20.1-linux-x64.tar.gz'
JDK_SHA256 = 'd00e5b04e9726b63d915706c7049e5297c9f40239ce8a12fcc68b7267fa91ad2'
TOOLS_SHA1 = "5fdcc763663eefb86a5b8879697aa6088b041e70"

def download(url, target, algorithm, expected):
    if not target.exists():
        partial = target.with_suffix(target.suffix + ".part")
        with urllib.request.urlopen(url, timeout=120) as response, partial.open("wb") as out:
            while chunk := response.read(1024 * 1024):
                out.write(chunk)
        partial.rename(target)
    with target.open("rb") as source:
        if hashlib.file_digest(source, algorithm).hexdigest() != expected:
            raise RuntimeError("Checksum mismatch: " + str(target))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path.home() / "garden-flutter-env")
    parser.add_argument("--android", action="store_true")
    parser.add_argument("--accept-android-licenses", action="store_true")
    args = parser.parse_args()
    root = args.directory.expanduser().resolve()
    root.mkdir(parents=True, exist_ok=True)
    archive = root / "flutter-sdk.tar.xz"
    if not (root / "flutter/bin/flutter").exists():
        download("https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_" +
                 FLUTTER_VERSION + "-stable.tar.xz", archive, "sha256", FLUTTER_SHA256)
        with tarfile.open(archive) as source:
            source.extractall(root, filter="data")
    env = dict(os.environ, CI="true", FLUTTER_SUPPRESS_ANALYTICS="true")
    env["ANDROID_HOME"] = str(root / "android-sdk")
    env["PATH"] = str(root / "flutter/bin") + os.pathsep + env["PATH"]
    if args.android:
        java = root / "jdk-17"
        if not (java / "bin/javac").exists():
            archive = root / "jdk-17.tar.gz"
            download(JDK_URL, archive, "sha256", JDK_SHA256)
            with tarfile.open(archive) as source:
                dirname = source.getmembers()[0].name.split("/")[0]
                source.extractall(root, filter="data")
            (root / dirname).rename(java)
        # Use the machine's trusted Java CA store when one is maintained by the OS.
        system_cas = Path("/etc/ssl/certs/java/cacerts")
        if system_cas.exists():
            shutil.copyfile(system_cas, java / "lib/security/cacerts")
        env["JAVA_HOME"] = str(java)
        env["PATH"] = str(java / "bin") + os.pathsep + env["PATH"]
        sdk = root / "android-sdk"
        manager = sdk / "cmdline-tools/latest/bin/sdkmanager"
        if not manager.exists():
            archive = root / "android-tools.zip"
            download("https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip",
                     archive, "sha1", TOOLS_SHA1)
            with zipfile.ZipFile(archive) as source:
                source.extractall(sdk / "cmdline-tools")
            (sdk / "cmdline-tools/cmdline-tools").rename(sdk / "cmdline-tools/latest")
            for path in manager.parent.iterdir():
                path.chmod(0o755)
        if args.accept_android_licenses:
            subprocess.run([str(manager), "--sdk_root=" + str(sdk), "--licenses"],
                           input="y\n" * 100, text=True, env=env, check=True)
        else:
            subprocess.run([str(manager), "--sdk_root=" + str(sdk), "--licenses"], env=env, check=True)
        # Install one package per invocation to avoid concurrent extraction
        # mixing the archives in shared temporary directories.
        java_tmp = root / "java-tmp"
        java_tmp.mkdir(exist_ok=True)
        env["JAVA_TOOL_OPTIONS"] = (env.get("JAVA_TOOL_OPTIONS", "") +
                                    " -Djava.io.tmpdir=" + str(java_tmp)).strip()
        for package in ["platform-tools", "platforms;android-34", "platforms;android-35",
                        "platforms;android-36", "build-tools;35.0.0", "ndk;27.0.12077973", "cmake;3.22.1"]:
            subprocess.run([str(manager), "--sdk_root=" + str(sdk), package], env=env, check=True)
    # CI=true prevents the SDK's automatic cloud metadata environment probe.
    import shlex
    (root / "activate.sh").write_text(
        "export CI=true\nexport FLUTTER_SUPPRESS_ANALYTICS=true\nexport ANDROID_HOME=" +
        shlex.quote(env["ANDROID_HOME"]) + "\nexport PATH=" + shlex.quote(str(root / "flutter/bin")) +
        ':"$PATH"\n')
    with (root / "activate.sh").open("a") as activation:
        activation.write('# Java/Gradle uses JVM proxy properties instead of the standard proxy variables.\nexport GRADLE_OPTS="${GRADLE_OPTS:-} $(python3 -c \'import os,urllib.parse; p=urllib.parse.urlparse(os.environ.get("https_proxy", os.environ.get("HTTPS_PROXY", ""))); print(" ".join("-D"+s+".proxyHost="+p.hostname+" -D"+s+".proxyPort="+str(p.port or 80) for s in ["http","https"]) if p.hostname else "")\')"\n')
    if args.android:
        with (root / "activate.sh").open("a") as activation:
            activation.write("export JAVA_HOME=" + shlex.quote(str(root / "jdk-17")) +
                             '\nexport PATH="$JAVA_HOME/bin:$PATH"\n')
    if args.android:
        # Flutter's saved SDK setting takes precedence over ANDROID_HOME.
        # Repoint it after recreating an environment in a new workspace.
        subprocess.run([str(root / "flutter/bin/flutter"), "config", "--android-sdk",
                        str(root / "android-sdk")], env=env, check=True)
    subprocess.run([str(root / "flutter/bin/flutter"), "--version"], env=env, check=True)
    print("Activate with: source " + str(root / "activate.sh"))

if __name__ == "__main__":
    main()
