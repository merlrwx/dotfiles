import { execFileSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export function shouldContinue(cwd: string): boolean {
  try {
    const state = JSON.parse(execFileSync("agent-goal", ["status", "--json"], {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }));
    return state.status === "active" && state.continue === true;
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
