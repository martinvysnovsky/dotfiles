// --------------------------------------
// **DISCLAIMER: THIS CAN GET YOU BANNED**
// --------------------------------------
// Drop this into your plugins folder and things should resume working.
// If you're on version > 1.2.27, you can also add an `anthropic-prompt.txt`
// file in the same plugins directory containing the opencode session prompt:
// https://github.com/anomalyco/opencode/blob/8e09e8c6121f03244a1f25281b506a90bcb355d7/packages/opencode/src/session/prompt/anthropic-20250930.txt

const CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e";
const VERSION = "2.1.79";
const AGENT = `claude-cli/${VERSION} (external, cli)`;
const SALT = "59cf53e54c78";
const ENTRY = "CLAUDE_CODE_ENTRYPOINT";
const PROMPT = new URL("./anthropic-prompt.txt", import.meta.url);
const PLATFORM_HOST = "platform.claude.com";
const LEGACY_CONSOLE_HOST = "console.anthropic.com";
const CALLBACK_URL = `https://${PLATFORM_HOST}/oauth/code/callback`;
const TOKEN_ENDPOINTS = [
  `https://${PLATFORM_HOST}/v1/oauth/token`,
  `https://${LEGACY_CONSOLE_HOST}/v1/oauth/token`,
];

const REQUIRED_BETAS = [
  "claude-code-20250219",
  "oauth-2025-04-20",
  // "context-1m-2025-08-07",
  "interleaved-thinking-2025-05-14",
  "redact-thinking-2026-02-12",
  "prompt-caching-scope-2026-01-05",
  "advanced-tool-use-2025-11-20",
  "effort-2025-11-24",
  "fast-mode-2026-02-01",
];

// ---- PKCE / OAuth helpers ----

async function prompt() {
  const file = Bun.file(PROMPT);
  if (!(await file.exists())) {
    return "You are Claude Code, Anthropic's official CLI for Claude.";
  }
  return file.text();
}

function base64url(input) {
  return Buffer.from(input)
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function random(size) {
  return base64url(crypto.getRandomValues(new Uint8Array(size)));
}

async function pkce() {
  const verifier = random(32);
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(verifier),
  );
  return { verifier, challenge: base64url(new Uint8Array(hash)) };
}

function authHeaders(extra = {}) {
  return { "Content-Type": "application/json", "User-Agent": AGENT, ...extra };
}

async function parseError(response) {
  const text = await response.text();
  try {
    const json = JSON.parse(text);
    return json?.error_description || json?.error?.message || text;
  } catch {
    return text || response.statusText;
  }
}

async function exchangeWithEndpoint(url, payload) {
  const res = await fetch(url, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    return {
      ok: false,
      endpoint: url,
      status: res.status,
      message: await parseError(res),
    };
  }
  return { ok: true, endpoint: url, json: await res.json() };
}

function normalizeCodeInput(input) {
  const trimmed = input.trim();
  if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://"))
    return trimmed;
  try {
    const url = new URL(trimmed);
    const code = url.searchParams.get("code");
    const state =
      url.searchParams.get("state") ||
      url.hash.replace(/^#/, "") ||
      url.searchParams.get("code_verifier");
    if (code) return `${code}#${state || ""}`;
  } catch {}
  return trimmed;
}

async function authorize(mode) {
  const code = await pkce();
  const url = new URL(
    `https://${mode === "console" ? PLATFORM_HOST : "claude.ai"}/oauth/authorize`,
  );
  url.searchParams.set("code", "true");
  url.searchParams.set("client_id", CLIENT_ID);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("redirect_uri", CALLBACK_URL);
  url.searchParams.set(
    "scope",
    "org:create_api_key user:profile user:inference",
  );
  url.searchParams.set("code_challenge", code.challenge);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("state", code.verifier);
  return { url: url.toString(), verifier: code.verifier };
}

async function exchange(code, verifier) {
  const split = normalizeCodeInput(code).split("#");
  const payload = {
    code: split[0],
    state: split[1],
    grant_type: "authorization_code",
    client_id: CLIENT_ID,
    redirect_uri: CALLBACK_URL,
    code_verifier: verifier,
  };
  let failure = null;
  for (const endpoint of TOKEN_ENDPOINTS) {
    const res = await exchangeWithEndpoint(endpoint, payload);
    if (res.ok) {
      const json = res.json;
      return {
        type: "success",
        refresh: json.refresh_token,
        access: json.access_token,
        expires: Date.now() + json.expires_in * 1000,
      };
    }
    failure = res;
  }
  return {
    type: "failed",
    error: failure?.message || "Token exchange failed.",
    status: failure?.status,
    endpoint: failure?.endpoint,
  };
}

// ---- Billing header ----

function firstUserText(messages) {
  if (!Array.isArray(messages)) return "";
  for (const msg of messages) {
    if (!msg || typeof msg !== "object" || msg.role !== "user") continue;
    if (typeof msg.content === "string") return msg.content;
    if (!Array.isArray(msg.content)) return "";
    for (const block of msg.content) {
      if (block?.type === "text" && typeof block.text === "string")
        return block.text;
    }
    return "";
  }
  return "";
}

function billingHeader(body) {
  const json = JSON.parse(body);
  const sample = [4, 7, 20]
    .map((idx) => firstUserText(json.messages).charAt(idx) || "0")
    .join("");
  const hash = Bun.CryptoHasher.hash(
    "sha256",
    `${SALT}${sample}${VERSION}`,
    "hex",
  ).slice(0, 3);
  const entry = process.env[ENTRY]?.trim() || "cli";
  const cch = Array.from(crypto.getRandomValues(new Uint8Array(3)))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, 5);
  return `cc_version=${VERSION}.${hash}; cc_entrypoint=${entry}; cch=${cch};`;
}

// ---- Request body transforms ----

function stripCacheControl(obj) {
  if (!obj || typeof obj !== "object") return obj;
  const { cache_control, ...rest } = obj;
  return rest;
}

function transformBody(body) {
  const json = JSON.parse(body);

  // Sanitize "opencode" references from system prompt text
  if (Array.isArray(json.system)) {
    json.system = json.system.map((item) => {
      if (
        !item ||
        typeof item !== "object" ||
        item.type !== "text" ||
        typeof item.text !== "string"
      )
        return item;
      return {
        ...item,
        text: item.text
          .replace(/OpenCode/g, "Claude Code")
          .replace(/opencode/gi, "Claude"),
      };
    });
  }

  // Prefix tool names with "mcp_"
  if (Array.isArray(json.tools)) {
    json.tools = json.tools.map((item) => {
      if (!item || typeof item !== "object" || typeof item.name !== "string")
        return item;
      return { ...item, name: `mcp_${item.name}` };
    });
  }

  // Prefix tool_use block names in messages with "mcp_"
  if (Array.isArray(json.messages)) {
    json.messages = json.messages.map((msg) => {
      if (!msg || typeof msg !== "object" || !Array.isArray(msg.content))
        return msg;
      return {
        ...msg,
        content: msg.content.map((item) => {
          if (!item || typeof item !== "object") return item;
          if (item.type === "tool_use" && typeof item.name === "string") {
            return { ...item, name: `mcp_${item.name}` };
          }
          return item;
        }),
      };
    });
  }

  // Strip cache_control — rejected on the OAuth path
  if (Array.isArray(json.system)) {
    json.system = json.system.map(stripCacheControl);
  }
  if (Array.isArray(json.messages)) {
    json.messages = json.messages.map((msg) => {
      if (!msg || typeof msg !== "object") return msg;
      const stripped = stripCacheControl(msg);
      if (Array.isArray(stripped.content)) {
        stripped.content = stripped.content.map(stripCacheControl);
      }
      return stripped;
    });
  }

  return JSON.stringify(json);
}

// ---- Response stream transform ----

function stripMcpPrefixFromStream(response) {
  if (!response.body) return response;
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async pull(ctrl) {
      const { done, value } = await reader.read();
      if (done) {
        ctrl.close();
        return;
      }
      const text = decoder
        .decode(value, { stream: true })
        .replace(/"name"\s*:\s*"mcp_([^"]+)"/g, '"name": "$1"');
      ctrl.enqueue(encoder.encode(text));
    },
  });
  return new Response(stream, {
    status: response.status,
    statusText: response.statusText,
    headers: response.headers,
  });
}

// ---- Token refresh ----

async function refreshToken(auth, client) {
  if (auth.access && auth.expires > Date.now()) return auth;

  const payload = {
    grant_type: "refresh_token",
    refresh_token: auth.refresh,
    client_id: CLIENT_ID,
  };
  let refreshed = null;
  for (const endpoint of TOKEN_ENDPOINTS) {
    const res = await exchangeWithEndpoint(endpoint, payload);
    if (res.ok) {
      refreshed = res.json;
      break;
    }
  }
  if (!refreshed)
    throw new Error(
      "Token refresh failed on all known Anthropic OAuth endpoints",
    );

  const updated = {
    type: "oauth",
    refresh: refreshed.refresh_token,
    access: refreshed.access_token,
    expires: Date.now() + refreshed.expires_in * 1000,
  };
  await client.auth.set({ path: { id: "anthropic" }, body: updated });
  return { ...auth, ...updated };
}

// ---- Main plugin ----

export async function AnthropicAuthPlugin({ client }) {
  return {
    async "experimental.chat.system.transform"(input, output) {
      if (input.model?.providerID !== "anthropic") return;
      const prefix = await prompt();

      // Remove any stale billing header blocks from previous runs
      for (let i = output.system.length - 1; i >= 0; i--) {
        if (
          typeof output.system[i] === "string" &&
          output.system[i].startsWith("x-anthropic-billing-header:")
        ) {
          output.system.splice(i, 1);
        }
      }

      output.system.unshift(prefix);
      if (output.system[1])
        output.system[1] = `${prefix}\n\n${output.system[1]}`;

      // Billing header block goes first, before the identity prefix
      const cch = Array.from(crypto.getRandomValues(new Uint8Array(3)))
        .map((b) => b.toString(16).padStart(2, "0"))
        .join("")
        .slice(0, 5);
      output.system.unshift(
        `x-anthropic-billing-header: cc_version=${VERSION}; cc_entrypoint=cli; cch=${cch};`,
      );
    },

    auth: {
      provider: "anthropic",

      async loader(getAuth, provider) {
        const auth = await getAuth();
        if (auth.type !== "oauth") return {};

        for (const model of Object.values(provider.models)) {
          model.cost = { input: 0, output: 0, cache: { read: 0, write: 0 } };
        }

        return {
          apiKey: "",
          async fetch(input, init) {
            let auth = await getAuth();
            if (auth.type !== "oauth") return fetch(input, init);

            auth = await refreshToken(auth, client);

            // Build headers
            const req = init ?? {};
            const headers = new Headers(
              input instanceof Request ? input.headers : undefined,
            );
            new Headers(req.headers).forEach((value, key) =>
              headers.set(key, value),
            );

            const existingBetas = (headers.get("anthropic-beta") || "")
              .split(",")
              .map((x) => x.trim())
              .filter(Boolean);
            headers.set(
              "anthropic-beta",
              [...new Set([...REQUIRED_BETAS, ...existingBetas])].join(","),
            );
            headers.set("authorization", `Bearer ${auth.access}`);
            headers.set("user-agent", AGENT);
            headers.delete("x-api-key");
            headers.set("accept", "application/json");
            headers.set("anthropic-dangerous-direct-browser-access", "true");
            headers.set("anthropic-version", "2023-06-01");
            headers.set("x-app", "cli");
            headers.set("x-stainless-arch", "x86_64");
            headers.set("x-stainless-lang", "js");
            headers.set("x-stainless-os", "Linux");
            headers.set("x-stainless-package-version", "0.74.0");
            headers.set("x-stainless-retry-count", "0");
            headers.set("x-stainless-runtime", "node");
            headers.set("x-stainless-runtime-version", "v24.14.0");
            headers.set("x-stainless-timeout", "600");

            // Transform body
            let body =
              typeof req.body === "string" ? transformBody(req.body) : req.body;

            // Resolve URL, set billing header, add beta param
            let url;
            try {
              if (typeof input === "string" || input instanceof URL)
                url = new URL(input.toString());
              if (input instanceof Request) url = new URL(input.url);
            } catch {}

            if (url?.pathname === "/v1/messages") {
              if (typeof body === "string")
                headers.set("x-anthropic-billing-header", billingHeader(body));
              if (!url.searchParams.has("beta")) {
                url.searchParams.set("beta", "true");
                input =
                  input instanceof Request
                    ? new Request(url.toString(), input)
                    : url;
              }
            }

            const res = await fetch(input, { ...req, body, headers });
            return stripMcpPrefixFromStream(res);
          },
        };
      },

      methods: [
        {
          label: "Claude Pro/Max",
          type: "oauth",
          authorize: async () => {
            const auth = await authorize("max");
            return {
              url: auth.url,
              instructions: "Paste the authorization code here: ",
              method: "code",
              callback: (code) => exchange(code, auth.verifier),
            };
          },
        },
        {
          label: "Create an API Key",
          type: "oauth",
          authorize: async () => {
            const auth = await authorize("console");
            return {
              url: auth.url,
              instructions: "Paste the authorization code here: ",
              method: "code",
              callback: async (code) => {
                const credentials = await exchange(code, auth.verifier);
                if (credentials.type === "failed") return credentials;
                const res = await fetch(
                  "https://api.anthropic.com/api/oauth/claude_cli/create_api_key",
                  {
                    method: "POST",
                    headers: authHeaders({
                      authorization: `Bearer ${credentials.access}`,
                    }),
                  },
                );
                const json = await res.json();
                return { type: "success", key: json.raw_key };
              },
            };
          },
        },
        {
          provider: "anthropic",
          label: "Manually enter API Key",
          type: "api",
        },
      ],
    },
  };
}

export default AnthropicAuthPlugin;
