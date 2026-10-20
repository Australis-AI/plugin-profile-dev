#!/usr/bin/env node
// Australis dev — read-only SQL against the project's Supabase database, through
// the Supabase Management API.
//
//   node supabase-lectura.mjs "<select ...>"
//   node supabase-lectura.mjs --file query.sql
//
// Reads SUPABASE_ACCESS_TOKEN (a personal access token, sbp_...) and
// SUPABASE_PROJECT_REF from .env.local, then .env, in the current folder. The
// ref falls back to the subdomain of NEXT_PUBLIC_SUPABASE_URL. Never prints the
// token. Every query runs with read_only: true (as supabase_read_only_user), only
// SELECT / WITH / SHOW / EXPLAIN statements are sent, and rows of tables whose
// name says they hold keys or tokens are never queried.

import { existsSync, readFileSync } from "node:fs";

function fail(message, code = 2) {
  console.error(message);
  process.exit(code);
}

function readEnv() {
  const values = {};
  for (const file of [".env.local", ".env"]) {
    if (!existsSync(file)) continue;
    const lines = readFileSync(file, "utf8").replace(/^﻿/, "").split(/\r?\n/);
    for (const line of lines) {
      const match = line.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
      if (!match || match[1] in values) continue;
      values[match[1]] = match[2].replace(/^(['"])(.*)\1$/, "$2");
    }
  }
  return values;
}

function assertReadOnly(sql) {
  const stripped = sql
    .replace(/--.*$/gm, "")
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .trim()
    .toLowerCase();
  if (!/^(select|with|show|explain)\b/.test(stripped)) {
    fail("Refused: only SELECT / WITH / SHOW / EXPLAIN statements are allowed.");
  }
  const code = stripped.replace(/'[^']*'/g, "''");
  if (/\b(insert|update|delete|drop|alter|create|truncate|grant|revoke|copy|call|do|vacuum|reindex|refresh|set|reset|lock)\b/.test(code)) {
    fail("Refused: the statement contains a write, DDL or session keyword.");
  }
  // Structure of these tables is read from the catalog; their rows never are.
  const sensitive = /\b(?:from|join)\s+(?:"?\w+"?\.)?"?(\w*(?:key|token|secret|credential|password)\w*)"?/;
  const hit = code.match(sensitive);
  if (hit) {
    fail(`Refused: "${hit[1]}" looks like it holds keys or tokens; its rows are never queried.`);
  }
}

async function main() {
  const args = process.argv.slice(2);
  const sql = args[0] === "--file" ? readFileSync(args[1] ?? "", "utf8") : args.join(" ");
  if (!sql.trim()) fail('Usage: node supabase-lectura.mjs "<select ...>" | --file query.sql');
  assertReadOnly(sql);

  const env = readEnv();
  const token = env.SUPABASE_ACCESS_TOKEN;
  const ref =
    env.SUPABASE_PROJECT_REF ||
    (env.NEXT_PUBLIC_SUPABASE_URL || "").match(/^https:\/\/([a-z0-9]+)\.supabase\.co/)?.[1];
  if (!token) fail("Missing SUPABASE_ACCESS_TOKEN in .env.local");
  if (!ref) fail("Missing SUPABASE_PROJECT_REF (or NEXT_PUBLIC_SUPABASE_URL) in .env.local");

  const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({ query: sql, read_only: true }),
  });
  const text = await res.text();
  if (!res.ok) fail(`HTTP ${res.status}: ${text.slice(0, 800)}`, 1);
  console.log(text);
}

main().catch((err) => fail(String(err?.message || err), 1));
