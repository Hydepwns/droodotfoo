import Config

# Production asset optimization
config :esbuild,
  droodotfoo: [
    args: ~w(
      js/app.js
      --bundle
      --target=es2022
      --outdir=../priv/static/assets/js
      --external:/fonts/*
      --external:/images/*
      --minify
      --tree-shaking=true
      --splitting
      --format=esm
      --chunk-names=chunks/[name]-[hash]
      --asset-names=[name]-[hash]
      --sourcemap=external
      --metafile=meta.json
      --drop:console
      --drop:debugger
      --legal-comments=none
      --alias:@=.
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_ENV" => "production",
      "NODE_PATH" => Path.expand("../deps", __DIR__)
    }
  ]

# Tailwind production config
config :tailwind,
  droodotfoo: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
      --minify
    ),
    cd: Path.expand("..", __DIR__)
  ]
