import { context, build } from "esbuild";
import { solidPlugin } from "esbuild-plugin-solid";
import fs from "fs";

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

// Define esbuild options
let opts = {
  entryPoints: ["js/app.js"],
  bundle: true,
  logLevel: "info",
  target: "es2022",
  outdir: "../priv/static/assets",
  external: ["*.css", "fonts/*", "images/*"],
  loader: { ".js": "jsx", ".svg": "file" },
  plugins: [solidPlugin()],
  nodePaths: ["../deps"],
  format: "esm",
};

if (deploy) {
  opts = {
    ...opts,
    minify: true,
    splitting: true,
    metafile: true,
  };
  let result = await build(opts);
  fs.writeFileSync("meta.json", JSON.stringify(result.metafile, null, 2));
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
  };

  context(opts)
    .then((ctx) => (watch ? ctx.watch() : build(opts)))
    .catch((error) => {
      console.log(`Build error: ${error}`);
      process.exit(1);
    });
}
