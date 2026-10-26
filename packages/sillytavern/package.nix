{
    buildNpmPackage,
    fetchFromGitHub,
    lib,
    tsuki,
}:

let
    serverPlugins = [
        tsuki.sillytavern-token-estimate
        tsuki.sillytavern-openai-response
    ];

    appDir = "$out/lib/node_modules/sillytavern";

    # Upstream imports getRawImage and getPipeline during startup, so both must
    # exist even though the model backend is gone.
    transformersStub = ''
        export async function getRawImage() {
            return null;
        }

        export async function getPipeline() {
            throw new Error('sillytavern-transformers is not available in this build');
        }

        export default {
            getRawImage,
            getPipeline,
        };
    '';
in
buildNpmPackage (finalAttrs: {
    pname = "sillytavern";
    version = "1.19.0";

    src = fetchFromGitHub {
        owner = "SillyTavern";
        repo = "SillyTavern";
        tag = finalAttrs.version;
        hash = "sha256-qBlR/4OnIyJeX9JWpzlrhGp/M+KeYqJDpAzI803jUqc=";
    };

    npmDepsHash = "sha256-wAVmQuchjDXh7sTj8Q7+bJJoYCi7JdvlEeC5G9VtjMU=";
    dontNpmBuild = true;
    npmInstallFlags = [ "--omit=dev" ];

    postPatch = ''
        # `.npmrc` breaks `npm pack`.
        rm .npmrc
    '';

    postInstall = ''
        # Build the browser bundle now; express.static serves it from public/.
        node ./docker/build-lib.js
        install -m 644 dist/_webpack/*/output/lib.js ${appDir}/public/lib.js
        install -m 644 dist/_webpack/*/output/lib.js.LICENSE.txt ${appDir}/public/lib.js.LICENSE.txt
        rm -rf dist

        cat > ${appDir}/src/middleware/webpack-serve.js <<'EOF'
        export default function getWebpackServeMiddleware() {
            const middleware = (req, res, next) => next();
            middleware.runWebpackCompiler = async () => {};
            return middleware;
        }
        EOF
        rm -f ${appDir}/webpack.config.js

        (
            cd ${appDir}
            chmod u+w package.json
            npm pkg delete \
                dependencies.webpack \
                dependencies.sillytavern-transformers \
                dependencies.tiktoken \
                dependencies.@agnai/web-tokenizers \
                dependencies.@agnai/sentencepiece-js
            # npm prune needs a lockfile to resolve offline. The app doesn't ship one.
            install -m 644 ${finalAttrs.src}/package-lock.json package-lock.json
            npm prune --omit=dev --no-save --offline --ignore-scripts --no-audit --no-fund
        )
        rm -f ${appDir}/package-lock.json ${appDir}/node_modules/.package-lock.json
        find ${appDir}/node_modules -maxdepth 1 -type d -empty -delete

        rm -f ${appDir}/src/transformers.js
        cat > ${appDir}/src/transformers.js <<'EOF'
        ${transformersStub}
        EOF

        # The token-estimate plugin swaps this router's count/encode handlers, so
        # those routes never load the models. Decode routes are not swapped and
        # return empty.
        rm -rf ${appDir}/src/tokenizers

        # tokenizers.js imports these packages at startup, so they must still
        # resolve after the real packages are pruned.
        make_stub() {
            local dir="${appDir}/node_modules/$1"
            install -d "$dir"
            printf '{"name":"%s","version":"0.0.0","type":"module","main":"index.js","exports":"./index.js"}\n' "$1" > "$dir/package.json"
            cat > "$dir/index.js"
        }

        make_stub tiktoken <<'EOF'
        export function encoding_for_model() {
            throw new Error('tiktoken is not available in this build');
        }

        export default {
            encoding_for_model,
        };
        EOF

        make_stub @agnai/web-tokenizers <<'EOF'
        export class Tokenizer {
            static async fromJSON() {
                throw new Error('@agnai/web-tokenizers is not available in this build');
            }
        }
        EOF

        make_stub @agnai/sentencepiece-js <<'EOF'
        export class SentencePieceProcessor {
            load() {
                throw new Error('@agnai/sentencepiece-js is not available in this build');
            }
        }
        EOF

        # Drop files only used for development.
        find ${appDir}/node_modules -type f \
            \( -name '*.map' -o -name '*.md' -o -name '*.markdown' \) -delete
        find ${appDir}/node_modules -type d \
            \( -name test -o -name tests -o -name __tests__ -o -name docs \) \
            -prune -exec rm -rf {} +
        rm -rf ${appDir}/.github ${appDir}/docker ${appDir}/tests ${appDir}/src/electron
        rm -f ${appDir}/jsconfig.json ${appDir}/public/jsconfig.json \
            ${appDir}/CONTRIBUTING.md ${appDir}/replit.nix \
            ${appDir}/Update-Instructions.txt ${appDir}/.replit ${appDir}/.nomedia \
            ${appDir}/*.bat ${appDir}/*.cmd ${appDir}/start.sh

        mkdir -p ${appDir}/backups ${appDir}/public/scripts/extensions/third-party
    '' + lib.concatMapStringsSep "\n" (p:
        # Copy rather than symlink because Node realpaths __dirname to the
        # plugin's store path, which breaks its relative lookup of SillyTavern's src/.
        ''cp -r "${p}" "${appDir}/plugins/${p.pname}"''
    ) serverPlugins;

    meta = {
        description = "LLM Frontend for Power Users";
        homepage = "https://docs.sillytavern.app/";
        license = lib.licenses.agpl3Only;
        mainProgram = "sillytavern";
    };
})