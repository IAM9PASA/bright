#!/usr/bin/env node
// bright ui simulator: runs an example with the real bright + vide code on a fake roblox (sim/roblox.luau)
// and draws the result in a browser page, so you can see the ui without opening studio.
//
//   node sim/run.mjs                      every example in sim/examples -> sim/out/<name>.html
//   node sim/run.mjs gallery              one example
//   node sim/run.mjs --shot               also save png screenshots + run design checks (needs playwright)
//   node sim/run.mjs --serve              local server on :5173 that rebuilds + reloads on save
//   node sim/run.mjs --device phone,desktop --shot
//   node sim/run.mjs --tests              run sim/tests (lint fixtures, behaviour asserts), exit 1 on failure
//   node sim/run.mjs --strict             exit 1 on any sizing-rule fail (RULES.md), for ci
//
// needs a `luau` binary: `rokit install` (rokit.toml) or set LUAU=/path/to/luau

import { spawnSync, execFileSync } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SIM = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.dirname(SIM);
const OUT = path.join(SIM, "out");
// --tests runs the assertion scripts in sim/tests instead of the examples
const EXAMPLES = path.join(SIM, process.argv.includes("--tests") ? "tests" : "examples");
const VIDE_VERSION = "0.3.1";

// sizes are roblox screen points. safe = notch / home bar insets. each example runs once per device
// with that viewport and touch setting, so code that checks the screen gets the real answer
const DEVICES = {
	phone: { label: "Phone landscape 844x390", width: 844, height: 390, touch: true, safe: { l: 47, r: 47, t: 0, b: 21 } },
	phone_portrait: { label: "Phone portrait 390x844", width: 390, height: 844, touch: true, safe: { l: 0, r: 0, t: 47, b: 34 } },
	small_phone: { label: "Small phone 667x375", width: 667, height: 375, touch: true, safe: { l: 0, r: 0, t: 0, b: 0 } },
	tablet: { label: "Tablet 1180x820", width: 1180, height: 820, touch: true, safe: { l: 0, r: 0, t: 0, b: 20 } },
	laptop: { label: "Laptop 1366x768", width: 1366, height: 768, touch: false, safe: { l: 0, r: 0, t: 0, b: 0 } },
	desktop: { label: "Desktop 1920x1080", width: 1920, height: 1080, touch: false, safe: { l: 0, r: 0, t: 0, b: 0 } },
	console: { label: "Console / TV 1920x1080", width: 1920, height: 1080, touch: false, tv: true, safe: { l: 0, r: 0, t: 0, b: 0 } },
};

const args = process.argv.slice(2);
const flag = (name) => args.includes(`--${name}`);
const option = (name, fallback) => {
	const i = args.indexOf(`--${name}`);
	return i >= 0 && args[i + 1] && !args[i + 1].startsWith("--") ? args[i + 1] : fallback;
};
const names = args.filter((a, i) => !a.startsWith("--") && !(i > 0 && ["device", "port"].includes(args[i - 1].slice(2))));

// LUAU + VIDE -------------------------

function find_luau() {
	const candidates = [process.env.LUAU, "luau", path.join(process.env.HOME ?? "", ".rokit/bin/luau")].filter(Boolean);
	for (const bin of candidates) {
		const probe = spawnSync(bin, ["--help"], { encoding: "utf8" });
		if (!probe.error) return bin;
	}
	fail("no luau binary found. run `rokit install` (luau is in rokit.toml) or set LUAU=/path/to/luau");
}

// wally install puts vide in Packages/_Index, otherwise clone the pinned tag once into sim/.cache
function find_vide() {
	if (process.env.VIDE) return path.join(process.env.VIDE, "src");
	const index = path.join(ROOT, "Packages", "_Index");
	if (fs.existsSync(index)) {
		const dir = fs.readdirSync(index).find((d) => d.startsWith("centau_vide@"));
		if (dir) {
			const src = path.join(index, dir, "vide", "src");
			if (fs.existsSync(src)) return src;
		}
	}
	const cache = path.join(SIM, ".cache", `vide-${VIDE_VERSION}`);
	if (!fs.existsSync(path.join(cache, "src", "init.luau"))) {
		console.log(`[sim] fetching vide ${VIDE_VERSION} into sim/.cache`);
		fs.mkdirSync(path.dirname(cache), { recursive: true });
		execFileSync("git", ["clone", "-q", "--depth", "1", "--branch", VIDE_VERSION, "https://github.com/centau/vide", cache], { stdio: "inherit" });
	}
	return path.join(cache, "src");
}

// a folder of .luau files as ModuleScripts: init.luau is the folder's own module, the rest are children
function collect_modules(dir, instance_path, out = []) {
	for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			collect_modules(full, `${instance_path}/${entry.name}`, out);
		} else if (/\.luau?$/.test(entry.name)) {
			const base = entry.name.replace(/\.luau?$/, "");
			out.push({ path: base === "init" ? instance_path : `${instance_path}/${base}`, source: fs.readFileSync(full, "utf8") });
		}
	}
	return out;
}

// FONTS -------------------------
// roblox font families -> open font files with the same (or a close) design, from @fontsource on npm.
// fetched once into sim/.cache/fonts. without them the viewer falls back to system fonts
const FONT_FILES = {
	GothamSSm: ["montserrat", "Montserrat"],
	Montserrat: ["montserrat", "Montserrat"],
	FredokaOne: ["fredoka", "Fredoka"],
	Michroma: ["michroma", "Michroma"],
	Merriweather: ["merriweather", "Merriweather"],
	Oswald: ["oswald", "Oswald"],
	Nunito: ["nunito", "Nunito"],
};
const FONT_DIR = path.join(SIM, ".cache", "fonts");

function fetch_fonts() {
	if (fs.existsSync(FONT_DIR) && fs.readdirSync(FONT_DIR).some((f) => f.endsWith(".woff2"))) return;
	try {
		fs.mkdirSync(FONT_DIR, { recursive: true });
		const packages = [...new Set(Object.values(FONT_FILES).map(([pkg]) => `@fontsource/${pkg}`))];
		execFileSync("npm", ["pack", ...packages, "--silent"], { cwd: FONT_DIR, stdio: "ignore" });
		for (const tgz of fs.readdirSync(FONT_DIR).filter((f) => f.endsWith(".tgz"))) {
			execFileSync("tar", ["-xzf", tgz, "--wildcards", "--strip-components=2", "package/files/*latin-[0-9]*-normal.woff2"], { cwd: FONT_DIR, stdio: "ignore" });
			fs.rmSync(path.join(FONT_DIR, tgz));
		}
	} catch {
		console.warn("[sim] could not fetch fonts (npm offline?), using system fonts");
	}
}

function font_css(json) {
	if (!fs.existsSync(FONT_DIR)) return "";
	const used = new Set([...json.matchAll(/families\/(\w+)\.json/g)].map((m) => m[1]));
	let css = "";
	for (const family of used) {
		const entry = FONT_FILES[family];
		if (!entry) continue;
		const [pkg, css_name] = entry;
		for (const file of fs.readdirSync(FONT_DIR).filter((f) => f.startsWith(`${pkg}-latin-`))) {
			const weight = file.match(/-(\d+)-normal/)[1];
			const data = fs.readFileSync(path.join(FONT_DIR, file)).toString("base64");
			css += `@font-face{font-family:"${css_name}";font-weight:${weight};src:url(data:font/woff2;base64,${data}) format("woff2")}\n`;
		}
	}
	return css;
}

// BUILD -------------------------

function long_string(text) {
	let level = 0;
	while (text.includes(`]${"=".repeat(level)}]`)) level++;
	const eq = "=".repeat(level);
	// a leading newline inside [[ ]] is dropped by lua, so add one to keep line numbers right
	return `[${eq}[\n${text}]${eq}]`;
}

function bundle(example, modules, device) {
	const list = modules.map((m) => `{ path = ${JSON.stringify(m.path)}, source = ${long_string(m.source)} }`).join(",\n");
	const name = path.basename(example).replace(/\.luau?$/, "");
	return [
		`SIM = { viewport = { ${device.width}, ${device.height} }, touch = ${device.touch}, gamepad = ${!!device.tv}, modules = {\n${list}\n},`,
		`main = { name = ${JSON.stringify(name)}, source = ${long_string(fs.readFileSync(example, "utf8"))} } }`,
		fs.readFileSync(path.join(SIM, "roblox.luau"), "utf8"),
	].join("\n");
}

const MARK = "\u0001SIMJSON\u0001";

function run_once(luau, modules, example, name, device_name, print_logs) {
	const bundle_path = path.join(OUT, `${name}.bundle.luau`);
	fs.writeFileSync(bundle_path, bundle(example, modules, DEVICES[device_name]));
	const result = spawnSync(luau, [bundle_path], { encoding: "utf8", maxBuffer: 256 * 1024 * 1024 });
	const stdout = result.stdout ?? "";
	const at = stdout.lastIndexOf(MARK);
	const logs = (at >= 0 ? stdout.slice(0, at) : stdout).trimEnd();
	if (logs && print_logs) console.log(logs.split("\n").map((l) => `  [${name}] ${l}`).join("\n"));
	if (result.status !== 0 || at < 0) {
		console.error(`\n[sim] ${name} failed (${device_name}):\n${(result.stderr || "").trim() || "no output"}\n`);
		return null;
	}
	return JSON.parse(stdout.slice(at + MARK.length));
}

function run_example(luau, modules, example) {
	const name = path.basename(example).replace(/\.luau?$/, "");
	fs.mkdirSync(OUT, { recursive: true });
	const data = { name, devices: DEVICES, runs: {}, assets: {} };
	for (const device_name of Object.keys(DEVICES)) {
		const run = run_once(luau, modules, example, name, device_name, device_name === "desktop");
		if (!run) return null;
		data.runs[device_name] = run.scenes;
		Object.assign(data.assets, run.assets);
	}
	data.scenes = data.runs.desktop.map((s) => ({ name: s.name }));

	// inline mapped images so the html works from file://
	for (const [id, file] of Object.entries(data.assets)) {
		const full = path.resolve(ROOT, file);
		if (!fs.existsSync(full)) {
			console.warn(`  [${name}] sim.asset: ${file} not found`);
			delete data.assets[id];
			continue;
		}
		const ext = path.extname(full).slice(1).toLowerCase();
		const mime = ext === "svg" ? "image/svg+xml" : `image/${ext === "jpg" ? "jpeg" : ext}`;
		data.assets[id] = `data:${mime};base64,${fs.readFileSync(full).toString("base64")}`;
	}

	const html_path = path.join(OUT, `${name}.html`);
	const template = fs.readFileSync(path.join(SIM, "view.html"), "utf8");
	const json = JSON.stringify(data).replace(/</g, "\\u003c");
	fs.writeFileSync(html_path, template.replace("/*SIM_DATA*/null", json).replace("/*SIM_FONTS*/", font_css(json)));
	fs.writeFileSync(path.join(OUT, `${name}.json`), JSON.stringify(data, null, 1));
	console.log(`[sim] ${name}: ${data.scenes.length} scene(s) -> ${path.relative(process.cwd(), html_path)}`);

	// sizing rules (src/lint.luau), same problems on every device so list each once
	const seen = new Set();
	const lint = [];
	for (const scenes of Object.values(data.runs)) {
		for (const scene of scenes) {
			for (const p of scene.lint || []) {
				const key = `${p.path}|${p.message}`;
				if (seen.has(key)) continue;
				seen.add(key);
				lint.push(p);
			}
		}
	}
	console.log(lint.length ? `[rules] ${name}: ${lint.length} problem(s)` : `[rules] ${name}: scale rules ok`);
	for (const p of lint) console.log(`    ${p.level.padEnd(4)} ${p.rule}: ${p.path} - ${p.message}`);
	return { name, html_path, data, lint };
}

function build_all() {
	const luau = find_luau();
	fetch_fonts();
	const modules = [
		...collect_modules(path.join(ROOT, "src"), "ReplicatedStorage/Packages/bright"),
		...collect_modules(find_vide(), "ReplicatedStorage/Packages/vide"),
		// helpers every example can require: ReplicatedStorage.Shared.<name>
		...(fs.existsSync(path.join(SIM, "shared")) ? collect_modules(path.join(SIM, "shared"), "ReplicatedStorage/Shared") : []),
	];
	const examples = fs.readdirSync(EXAMPLES).filter((f) => /\.luau?$/.test(f))
		.filter((f) => names.length === 0 || names.includes(f.replace(/\.luau?$/, "")))
		.map((f) => path.join(EXAMPLES, f));
	if (examples.length === 0) fail(`no examples matched ${names.join(", ")} in sim/examples`);
	return examples.map((e) => run_example(luau, modules, e)).filter(Boolean);
}

// SCREENSHOTS + CHECKS -------------------------

async function shoot(builds) {
	let playwright;
	try {
		playwright = await import("playwright");
	} catch {
		// global installs are only visible to require (NODE_PATH)
		try { playwright = createRequire(import.meta.url)("playwright"); } catch {}
	}
	if (!playwright) {
		fail("--shot needs playwright: npm i -D playwright && npx playwright install chromium");
	}
	const devices = option("device", "phone,desktop").split(",");
	const browser = await playwright.chromium.launch();
	const page = await browser.newPage({ deviceScaleFactor: 1 });
	let problems = 0;
	for (const build of builds) {
		await page.goto(`file://${build.html_path}`);
		await page.waitForFunction(() => window.sim?.ready);
		for (let scene = 0; scene < build.data.scenes.length; scene++) {
			for (const device of devices) {
				if (!DEVICES[device]) fail(`unknown device ${device}, pick from ${Object.keys(DEVICES).join(", ")}`);
				const info = await page.evaluate(([s, d]) => window.sim.show({ scene: s, device: d, bare: true }), [scene, device]);
				await page.setViewportSize({ width: info.width, height: info.height });
				await page.evaluate(([s, d]) => window.sim.show({ scene: s, device: d, bare: true }), [scene, device]);
				const label = build.data.scenes[scene].name.replace(/[^\w-]+/g, "_");
				const file = path.join(OUT, `${build.name}.${label}.${device}.png`);
				await page.locator("#screen").screenshot({ path: file });
				const checks = await page.evaluate(() => window.sim.checks);
				problems += checks.length;
				console.log(`[shot] ${path.relative(process.cwd(), file)}${checks.length ? `  ${checks.length} check(s):` : "  checks ok"}`);
				for (const c of checks) console.log(`    ${c.level.padEnd(4)} ${c.rule}: ${c.path} - ${c.message}`);
			}
		}
	}
	await browser.close();
	return problems;
}

// SERVE -------------------------

function serve() {
	const port = Number(option("port", 5173));
	const clients = new Set();
	let builds = build_all();
	let timer;
	const rebuild = () => {
		clearTimeout(timer);
		timer = setTimeout(() => {
			builds = build_all();
			for (const res of clients) res.write("data: reload\n\n");
		}, 120);
	};
	for (const dir of [path.join(ROOT, "src"), EXAMPLES, path.join(SIM, "shared")].filter((d) => fs.existsSync(d))) fs.watch(dir, { recursive: true }, rebuild);
	fs.watch(path.join(SIM, "view.html"), rebuild);
	fs.watch(path.join(SIM, "roblox.luau"), rebuild);

	http.createServer((req, res) => {
		const url = new URL(req.url, "http://x");
		if (url.pathname === "/events") {
			res.writeHead(200, { "content-type": "text/event-stream", "cache-control": "no-cache" });
			clients.add(res);
			req.on("close", () => clients.delete(res));
			return;
		}
		const name = url.pathname.slice(1) || builds[0]?.name;
		const file = path.join(OUT, `${name}.html`);
		if (!name || !fs.existsSync(file)) {
			res.writeHead(404, { "content-type": "text/html" });
			res.end(builds.map((b) => `<a href="/${b.name}">${b.name}</a>`).join("<br>"));
			return;
		}
		res.writeHead(200, { "content-type": "text/html", "cache-control": "no-store" });
		res.end(fs.readFileSync(file, "utf8").replace("</body>", `<script>new EventSource("/events").onmessage = () => location.reload()</script></body>`));
	}).listen(port, () => console.log(`[sim] serving on http://localhost:${port}/ (rebuilds on save)`));
}

// MAIN -------------------------

function fail(message) {
	console.error(`[sim] ${message}`);
	process.exit(1);
}

if (flag("serve")) {
	serve();
} else {
	const builds = build_all();
	// --strict: rule fails (and with --shot, any design check) exit non-zero, for ci
	const rule_fails = builds.reduce((n, b) => n + b.lint.filter((p) => p.level === "fail").length, 0);
	let problems = rule_fails;
	if (flag("shot")) problems += await shoot(builds);
	if (flag("strict") && problems > 0) process.exit(1);
	if (builds.length === 0) process.exit(1);
}
