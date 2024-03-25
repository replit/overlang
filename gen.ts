import { Type } from "@sinclair/typebox";
import { Value } from "@sinclair/typebox/value";
import assert from "assert";

interface NodeVersionMeta {
	url: string;
	sha256: string;
}

class PatchVersionMap extends Map<number, NodeVersionMeta> {
	get latestPatch(): number {
		return [...this.keys()].sort().pop() ?? -1;
	}
}

class MinorVersionMap extends Map<number, PatchVersionMap> {
	get latestMinor(): number {
		return [...this.keys()].sort().pop() ?? -1;
	}
}

class MajorVersionMap extends Map<number, MinorVersionMap> {
	get latestMajor(): number {
		return [...this.keys()].sort().pop() ?? -1;
	}

	setVersion(
		[major, minor, patch]: [number, number, number],
		meta: NodeVersionMeta,
	): void {
		if (!this.has(major)) {
			this.set(major, new MinorVersionMap());
		}

		const minorVersions = this.get(major)!;
		if (!minorVersions.has(minor)) {
			minorVersions.set(minor, new PatchVersionMap());
		}

		const patchVersions = minorVersions.get(minor)!;
		if (patchVersions.has(patch)) {
			throw new Error(`Duplicate version ${major}.${minor}.${patch}`);
		}

		patchVersions.set(patch, meta);
	}

	codegen(): string {
		const builders: string[] = [];
		const versions: string[] = [];
		const latestAliases: string[] = [
			`latest = latest-aliases."${this.latestMajor}.latest";`,
		];

		for (const [major, minors] of this) {
			builders.push(`v${major} = callPackage ./build/v${major}.nix {};`);
			latestAliases.push(
				`"${major}.latest" = latest-aliases."${major}.${minors.latestMinor}.latest";`,
			);

			for (const [minor, patches] of minors) {
				latestAliases.push(
					`"${major}.${minor}.latest" = versions."${major}.${minor}.${patches.latestPatch}";`,
				);

				for (const [patch, meta] of patches) {
					versions.push(`
						"${major}.${minor}.${patch}" = build.v${major} {
							version = "${major}.${minor}.${patch}";
							src = fetchurl {
								url = "${meta.url}";
								sha256 = "${meta.sha256}";
							};
						};
					`);
				}
			}
		}

		const buildersString = builders.join("\n");
		const versionsString = versions.join("\n");
		const latestAliasesString = latestAliases.join("\n");

		return `
			{ callPackage, fetchurl }:

			let
				build = { ${buildersString} };

				versions = { ${versionsString} };

				latest-aliases = { ${latestAliasesString} };
			in versions // latest-aliases
		`;
	}
}

async function nodejs(): Promise<string> {
	const NodeIndexJson = Type.Array(
		Type.Object({
			version: Type.String(),
			date: Type.String(),
			files: Type.Array(Type.String()),
			v8: Type.String(),
			lts: Type.Union([Type.String(), Type.Boolean()]),
			security: Type.Boolean(),

			// the earliest versions don't have these fields
			npm: Type.Optional(Type.String()),
			uv: Type.Optional(Type.String()),
			zlib: Type.Optional(Type.String()),
			openssl: Type.Optional(Type.String()),
			modules: Type.Optional(Type.String()),
		}),
	);

	// step 1: fetch the node.js version index
	const nodejsIndexURL = "https://nodejs.org/download/release/index.json";
	const nodejsIndexResp = await fetch(nodejsIndexURL);
	if (!nodejsIndexResp.ok) {
		throw new Error(
			`Failed to fetch node.js release index from ${nodejsIndexURL}: ${nodejsIndexResp.statusText}`,
		);
	}

	const nodejsIndexJson = await nodejsIndexResp.json();
	if (!Value.Check(NodeIndexJson, nodejsIndexJson)) {
		const errors = [...Value.Errors(NodeIndexJson, nodejsIndexJson)];
		throw new Error(
			`malformed response for nodejs index from ${nodejsIndexURL}`,
			{
				cause: errors,
			},
		);
	}

	// step 2: parse the versions, filter out the ones we aren't handling, and sort (to ensure consistency)
	const versions = nodejsIndexJson
		.map((release) => {
			return {
				versionString: release.version.substring(1),
				version: release.version
					.substring(1)
					.split(".")
					.map((vPart) => parseInt(vPart, 10)) as [number, number, number],
			};
		})
		.filter(({ version }) => version[0] >= 21)
		.sort(
			(
				{ version: [leftMajor, leftMinor, leftPatch] },
				{ version: [rightMajor, rightMinor, rightPatch] },
			) => {
				const majorDiff = leftMajor - rightMajor;
				if (majorDiff !== 0) {
					return majorDiff;
				}

				const minorDiff = leftMinor - rightMinor;
				if (minorDiff !== 0) {
					return minorDiff;
				}

				return leftPatch - rightPatch;
			},
		);

	// step 3: insert each version into the version map
	const versionMap = new MajorVersionMap();
	// match `deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef	node-v99.99.99.tar.xz`
	const sourceHashLineReg =
		/^([a-fA-F0-9]{64})\s+node-v(\d{1,2}\.\d{1,2}\.\d{1,2})\.tar\.xz$/;
	for (const { version, versionString } of versions) {
		// step 3a: get the SHASUMS256.txt file of the target release
		const hashFileURL = `https://nodejs.org/download/release/v${versionString}/SHASUMS256.txt`;
		const hashFileResp = await fetch(hashFileURL);
		if (!hashFileResp.ok) {
			throw new Error(
				`Failed to get hash file from ${hashFileURL}: ${hashFileResp.statusText}`,
			);
		}

		// step 3b: read the sha256 hash of the source tarball (we target .tar.xz because it's smaller than .tar.gz)
		const hashFileText = await hashFileResp.text();
		let sourceHash: string | null = null;
		for (const line of hashFileText.split("\n")) {
			const matches = sourceHashLineReg.exec(line);
			if (!matches) {
				continue;
			}

			const fileVersion = matches[2];
			if (fileVersion !== versionString) {
				throw new Error(
					`unexpected file in release ${hashFileURL}: ${fileVersion}`,
				);
			}

			sourceHash = matches[1];
		}

		if (sourceHash === null) {
			throw new Error(`No hash found for source tarball in ${hashFileURL}`);
		}

		versionMap.setVersion(version, {
			url: `https://nodejs.org/download/release/v${versionString}/node-v${versionString}.tar.xz`,
			sha256: sourceHash,
		});
	}

	return versionMap.codegen();
}

const nodejsNix = await nodejs();
const res = await Bun.write("nodejs/default.nix", nodejsNix);
assert.equal(nodejsNix.length, res, "Full file not written");
