// Force the Google Drive OAuth flow for one account label.
// The server itself authorizes lazily on first tool call, so starting it does
// nothing; this calls the auth path directly. Usage: node drive-auth.mjs <label>
import fs from "fs";
import path from "path";
import os from "os";

const label = process.argv[2];
if (!label) { console.error("usage: node drive-auth.mjs <label>"); process.exit(1); }

const dir = path.join(os.homedir(), ".gdrive-mcp", label);
const keyfile = path.join(dir, "gcp-oauth.keys.json");
if (!fs.existsSync(keyfile)) {
  console.error(`No keys file at ${keyfile} — run bootstrap.sh first.`); process.exit(1);
}
const keys = JSON.parse(fs.readFileSync(keyfile, "utf8")).installed;

// auth.js reads these at module load, so set them before importing.
process.env.GDRIVE_CREDS_DIR = dir;
process.env.CLIENT_ID = keys.client_id;
process.env.CLIENT_SECRET = keys.client_secret;

const mod = path.join(os.homedir(), ".gdrive-mcp", "node_modules",
                      "@isaacphi", "mcp-gdrive", "dist", "auth.js");
const { getValidCredentials } = await import(mod);

console.error(`\n=== Authorizing Drive for: ${label} ===`);
console.error("Sign in with the intended account when the browser opens.");
console.error("NOTE: 30-second timeout — do not linger on the account picker.\n");

await getValidCredentials(true);   // force, skip the quiet load

const tokenPath = path.join(dir, ".gdrive-server-credentials.json");
if (fs.existsSync(tokenPath)) {
  fs.chmodSync(tokenPath, 0o600);
  const c = JSON.parse(fs.readFileSync(tokenPath, "utf8"));
  console.error(`\nSUCCESS — token saved for '${label}'`);
  console.error("  scopes:", c.scope);
  console.error("  refresh_token:", !!c.refresh_token);
} else {
  console.error("\nFAILED — no token written. Re-run and finish sign-in within 30s.");
  process.exit(1);
}
process.exit(0);
