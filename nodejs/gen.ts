import { type Static, Type } from "@sinclair/typebox";
import { Value } from "@sinclair/typebox/value";

type ParsedVersion = [number, number, number];

const NodeIndexVersion = Type.Object({
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
});

const NodeIndexJson = Type.Array(NodeIndexVersion);

const VersionsJson = Type.Record(Type.String(), Type.String());

const NODE_INDEX_URL = "https://nodejs.org/download/release/index.json";

export default async function versionsJSON(): Promise<object> {
	const nodejsIndexResp = await fetch(NODE_INDEX_URL);
	if (!nodejsIndexResp.ok) {
		throw new Error(
			`Failed to fetch node.js release index from ${NODE_INDEX_URL}: ${nodejsIndexResp.statusText}`,
		);
	}

	const nodejsIndexJson = await nodejsIndexResp.json();
	if (!Value.Check(NodeIndexJson, nodejsIndexJson)) {
		const errors = [...Value.Errors(NodeIndexJson, nodejsIndexJson)];
		throw new Error(
			`malformed response for nodejs index from ${NODE_INDEX_URL}`,
			{
				cause: errors,
			},
		);
	}

	const versionsJson = await nodejsIndexJson
		.filter(releaseFilter)
		.reduce<Promise<typeof VersionsJson>>(
			(registryPromise, release) =>
				getVersionSum(release.version).then((shasum) =>
					registryPromise.then((registry) => {
						registry[release.version.substring(1)] = shasum;

						return registry;
					}),
				),
			Promise.resolve({} as typeof VersionsJson),
		);

	return versionsJson;
}

const getVersionURL = (version: string) =>
	`https://nodejs.org/download/release/${version}`;

async function getVersionSum(version: string): Promise<string> {
	const versionURL = getVersionURL(version);

	const shasumFileURL = `${versionURL}/SHASUMS256.txt`;
	const shasumFileResp = await fetch(shasumFileURL);
	if (!shasumFileResp.ok) {
		throw new Error(
			`Failed to fetch SHASUMS256.txt from ${shasumFileURL}: ${shasumFileResp.statusText}`,
		);
	}

	// match `deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef	node-v99.99.99.tar.xz`
	const sourceHashReg =
		/^([a-fA-F0-9]{64})\s+node-(v\d{1,2}\.\d{1,2}\.\d{1,2})\.tar\.xz$/;

	const shasumFileText = await shasumFileResp.text();
	const shasums = shasumFileText.split("\n").flatMap((line) => {
		const matches = line.match(sourceHashReg);
		if (!matches) {
			return [];
		}

		// sanity check
		const fileVersion = matches[2];
		if (fileVersion !== version) {
			throw new Error(`Version mismatch: ${fileVersion} !== ${version}`);
		}

		return [matches[1]];
	});

	if (shasums.length !== 1) {
		throw new Error(`no shasum found for ${version} in ${shasumFileURL}`);
	}

	return shasums[0];
}

function releaseFilter({ version }: Static<typeof NodeIndexVersion>): boolean {
	const parsed = version.substring(1).split(".").map(Number) as ParsedVersion;
	if (parsed.length !== 3) {
		throw new Error(`unexpected version ${version}`);
	}

	const [major] = parsed;
	return major >= 21;
}
