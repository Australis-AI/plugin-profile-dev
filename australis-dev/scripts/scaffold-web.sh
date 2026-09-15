#!/usr/bin/env bash
# Australis dev — scaffold the Australis web stack into an existing repository.
#
#   bash scaffold-web.sh <slug>
#
# Run from the root of a freshly cloned repository (README from GitHub, maybe
# .australis/). Builds Next.js (App Router, TypeScript, Tailwind, ESLint) in a
# temporary folder — create-next-app refuses non-empty folders — copies it in,
# then adds Vitest, Testing Library and the Supabase client.
#
# Nothing is copied until the temporary build succeeded. If installing
# dependencies fails afterwards, running the script again resumes there.
# Prints SCAFFOLD_OK on success. Needs Node and network.

set -eu

slug="${1:-}"
case "$slug" in
  ""|*[!a-z0-9-]*) echo "uso: scaffold-web.sh <slug en minúsculas, números y guiones>" >&2; exit 2 ;;
esac

command -v node >/dev/null 2>&1 || PATH="/c/Program Files/nodejs:$PATH"
command -v npx >/dev/null 2>&1 || { echo "Falta Node: corré /preparar." >&2; exit 4; }

repo="$(pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
app="$tmp/app"

# Re-running after a failed install resumes at the dependencies step.
resume=no
if [ -f package.json ]; then
  if grep -q '^Stack: australis' README.md 2>/dev/null; then
    resume=yes
  else
    echo "Ya hay un package.json acá: no es un proyecto nuevo." >&2; exit 3
  fi
fi

if [ "$resume" = no ]; then

echo "Creando la app base (esto tarda un par de minutos)..."
( cd "$tmp" && npx --yes create-next-app@16 app \
    --ts --app --tailwind --eslint --import-alias "@/*" \
    --use-npm --skip-install --disable-git --yes ) >"$tmp/create.log" 2>&1 \
  || { tail -20 "$tmp/create.log" >&2; echo "No se pudo crear la app base." >&2; exit 5; }

[ -f "$app/package.json" ] || { echo "La app base no quedó creada." >&2; exit 5; }

# --- package.json: name and test scripts ------------------------------------------
node -e '
  const fs = require("fs");
  const p = process.argv[1] + "/package.json";
  const pkg = JSON.parse(fs.readFileSync(p, "utf8"));
  pkg.name = process.argv[2];
  pkg.scripts = Object.assign({}, pkg.scripts, { test: "vitest run", "test:watch": "vitest" });
  // The Next template pins @types/node ^20, which conflicts with Vitest 5 peers.
  pkg.devDependencies = Object.assign({}, pkg.devDependencies, { "@types/node": "^24" });
  fs.writeFileSync(p, JSON.stringify(pkg, null, 2) + "\n");
' "$app" "$slug"

# --- test setup ------------------------------------------------------------------
cat > "$app/vitest.config.mts" <<'EOF'
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { "@": fileURLToPath(new URL("./", import.meta.url)) },
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./vitest.setup.ts"],
    exclude: ["node_modules", ".next"],
  },
});
EOF

cat > "$app/vitest.setup.ts" <<'EOF'
import "@testing-library/jest-dom/vitest";
EOF

mkdir -p "$app/lib"
cat > "$app/lib/supabase.ts" <<'EOF'
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

export const isSupabaseConfigured = Boolean(url && publishableKey);

// Browser-safe client: the publishable key is public by design and every table
// is protected by row-level security. Never use a secret or service-role key here.
export const supabase = isSupabaseConfigured
  ? createClient(url as string, publishableKey as string)
  : null;
EOF

cat > "$app/lib/supabase.test.ts" <<'EOF'
import { describe, expect, it } from "vitest";
import { isSupabaseConfigured } from "./supabase";

describe("supabase client", () => {
  it("reports whether the connection is configured", () => {
    expect(typeof isSupabaseConfigured).toBe("boolean");
  });
});
EOF

cat > "$app/app/page.test.tsx" <<'EOF'
import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Page from "./page";

describe("home page", () => {
  it("renders a main landmark", () => {
    render(<Page />);
    expect(screen.getByRole("main")).toBeInTheDocument();
  });
});
EOF

cat > "$app/.env.example" <<'EOF'
# Copy to .env.local and fill in from Supabase: Project Settings > API Keys.
# Both values are public by design. Never put a secret or service_role key here.
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
EOF

mkdir -p "$app/supabase/migrations"
touch "$app/supabase/migrations/.gitkeep"

# --- copy into the repository -----------------------------------------------------
# README.md and .gitignore from GitHub are merged, not overwritten.
( cd "$app" && find . -mindepth 1 -maxdepth 1 ! -name README.md ! -name .gitignore ! -name node_modules ! -name .git ) \
  | while read -r entry; do cp -R "$app/${entry#./}" "$repo/"; done

touch "$repo/.gitignore"
cat "$app/.gitignore" >> "$repo/.gitignore"
for line in '.env*' '!.env.example' '.australis/'; do
  grep -qxF "$line" "$repo/.gitignore" || printf '%s\n' "$line" >> "$repo/.gitignore"
done
awk '!seen[$0]++ || $0 == ""' "$repo/.gitignore" > "$tmp/gitignore" && cp "$tmp/gitignore" "$repo/.gitignore"

if ! grep -q '^Stack: australis' "$repo/README.md" 2>/dev/null; then
  printf '\nStack: australis (Next.js + Supabase + Vitest)\n' >> "$repo/README.md"
fi

fi  # resume = no

# --- dependencies ----------------------------------------------------------------
echo "Instalando dependencias..."
cd "$repo"
npm install >"$tmp/install.log" 2>&1 || { tail -20 "$tmp/install.log" >&2; echo "Falló la instalación de dependencias." >&2; exit 6; }
npm install @supabase/supabase-js >>"$tmp/install.log" 2>&1 || { tail -20 "$tmp/install.log" >&2; exit 6; }
npm install -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/dom @testing-library/jest-dom >>"$tmp/install.log" 2>&1 \
  || { tail -20 "$tmp/install.log" >&2; exit 6; }

echo "SCAFFOLD_OK"
