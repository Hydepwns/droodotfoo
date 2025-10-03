const esbuild = require("esbuild");
const path = require("path");

// Production optimization settings
const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const loader = {
  ".ttf": "file",
  ".woff": "file",
  ".woff2": "file",
  ".eot": "file",
  ".svg": "file",
  ".png": "file",
  ".jpg": "file",
  ".jpeg": "file",
  ".gif": "file",
};

const plugins = [];

// Bundle analyzer plugin for development
if (!deploy && !watch) {
  const { BundleAnalyzerPlugin } = require("esbuild-plugin-bundle-analyzer");
  plugins.push(BundleAnalyzerPlugin());
}

let opts = {
  entryPoints: ["js/app.js"],
  bundle: true,
  target: "es2022",
  outdir: "../priv/static/assets/js",
  logLevel: "info",
  loader,
  plugins,
  external: ["/fonts/*", "/images/*"],
  alias: {
    "@": path.resolve(__dirname),
  },
  metafile: true,  // Generate metafile for analysis
  treeShaking: true,  // Enable tree shaking
  sourcemap: deploy ? false : "inline",  // Disable sourcemaps in production
};

// Production optimizations
if (deploy) {
  opts = {
    ...opts,
    minify: true,
    mangleProps: /^_/,  // Mangle private properties
    splitting: true,  // Enable code splitting
    format: "esm",  // Use ES modules for better tree shaking
    chunkNames: "chunks/[name]-[hash]",
    assetNames: "[name]-[hash]",
    pure: ["console.log", "console.info"],  // Remove console logs in production
    drop: ["debugger"],  // Remove debugger statements
    legalComments: "none",  // Remove all comments
  };
}

if (watch) {
  opts = {
    ...opts,
    sourcemap: "inline",
    watch: {
      onRebuild(error) {
        if (error) console.error("Watch build failed:", error);
        else console.log("Watch build succeeded");
      },
    },
  };

  esbuild
    .context(opts)
    .then((ctx) => {
      ctx.watch();
    })
    .catch((_e) => {
      process.exit(1);
    });
} else {
  esbuild.build(opts).then((result) => {
    // Output bundle size analysis
    if (result.metafile) {
      const text = esbuild.analyzeMetafile(result.metafile, {
        verbose: false,
      });
      console.log("\n📊 Bundle Analysis:");
      console.log(text);

      // Calculate total size
      const outputs = result.metafile.outputs;
      const totalSize = Object.values(outputs).reduce((acc, output) => acc + output.bytes, 0);
      console.log(`\n📦 Total Bundle Size: ${(totalSize / 1024).toFixed(2)} KB`);

      // Save metafile for further analysis
      require("fs").writeFileSync("meta.json", JSON.stringify(result.metafile));
      console.log("\n💾 Metafile saved to meta.json for detailed analysis");
    }
  }).catch((_e) => {
    process.exit(1);
  });
}