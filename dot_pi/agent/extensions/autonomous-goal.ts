import { createHash } from "node:crypto";
import { accessSync, constants, existsSync, readFileSync, realpathSync, statSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ActiveGoal = {
  version: number;
  verifier: string;
  verifier_sha256: string;
};

export function shouldContinue(cwd: string): boolean {
  try {
    const root = realpathSync(execFileSync("git", ["rev-parse", "--show-toplevel"], {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim());
    const stateDir = resolve(root, ".agent");
    const activePath = resolve(stateDir, "ACTIVE");

    for (const marker of ["COMPLETE", "PAUSE", "BLOCKED.md"]) {
      if (existsSync(resolve(stateDir, marker))) return false;
    }

    const active = JSON.parse(readFileSync(activePath, "utf8")) as ActiveGoal;
    if (
      active.version !== 1 ||
      typeof active.verifier !== "string" ||
      !/^[a-f0-9]{64}$/.test(active.verifier_sha256)
    ) {
      return false;
    }

    const verifierPath = realpathSync(resolve(root, active.verifier));
    const verifierRelative = relative(root, verifierPath);
    if (
      !verifierRelative ||
      verifierRelative === ".." ||
      verifierRelative.startsWith(`..${sep}`) ||
      isAbsolute(verifierRelative)
    ) {
      return false;
    }
    if (!statSync(verifierPath).isFile()) return false;
    accessSync(verifierPath, constants.X_OK);

    const actualHash = createHash("sha256").update(readFileSync(verifierPath)).digest("hex");
    return actualHash === active.verifier_sha256;
  } catch {
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_before_settle", async (_event, ctx) => {
    if (!shouldContinue(ctx.cwd)) return;

    return {
      entries: [
        {
          type: "custom_message",
          customType: "autonomous-goal",
          display: false,
          content:
            "An autonomous goal is active in this repository. Read .agent/GOAL.md and .agent/PROGRESS.md, then continue with the next useful action. Implement and verify the acceptance criteria, updating PROGRESS.md concisely. When all criteria pass, run `agent-goal complete`. Use `agent-goal block` only for a genuine unavailable external dependency, with evidence and a recovery action.",
        },
      ],
      continue: true,
    };
  });
}
