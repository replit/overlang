import nodejs from "./nodejs/gen";
import assert from "node:assert";

const versionsJSONData = await nodejs();
// newline appended to satisfy biome
const versionsJSON = `${JSON.stringify(versionsJSONData, null, "\t")}\n`;
const written = await Bun.write("nodejs/versions.json", versionsJSON);
assert.equal(written, versionsJSON.length, "full versions.json wasn't written");
