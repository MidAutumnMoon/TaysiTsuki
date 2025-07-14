// # Reason of choosing rsbuild
//
// 1. mpv uses mujs, which only supports f ES5.
// This rules out esbuild, parcel etc. because of
// the lacking of ES5 support.
//
// 2. No one should be using webpack in this era.
//
// 3. Deno

import { defineConfig } from '@rsbuild/core';
import RspackDenoPlugin from 'rspack-deno-plugin';

export default defineConfig( {
    tools: {
        rspack: {
            plugins: [ new RspackDenoPlugin() ],
            // idoit mujs
            target: "es5",
            output: {
                chunkFormat: "commonjs",
                // no need of any kind of module
                enabledLibraryTypes: [],
            }
        }
    },
    source: {
        entry: {
            hello: "./src/hello.ts",
        }
    },
    output: {
        target: "node",
        overrideBrowserslist: [ "IE 11", ],
        polyfill: "usage",
        distPath: {
            root: "scripts"
        },
    }
} )
