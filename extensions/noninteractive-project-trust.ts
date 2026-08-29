import { execFile } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { promisify } from "node:util";
import type {
  ExtensionAPI,
  ProjectTrustEventResult,
} from "@earendil-works/pi-coding-agent";

const execFileAsync = promisify(execFile);
const GIT_COMMAND_TIMEOUT_MS = 5_000;
const GIT_OUTPUT_LIMIT_BYTES = 1024 * 1024;

async function gitOutput(cwd: string, args: string[]): Promise<string | undefined> {
  try {
    const { stdout } = await execFileAsync("git", ["-C", cwd, ...args], {
      encoding: "utf8",
      maxBuffer: GIT_OUTPUT_LIMIT_BYTES,
      timeout: GIT_COMMAND_TIMEOUT_MS,
    });
    return stdout.trim();
  } catch {
    return undefined;
  }
}

function isWithin(parent: string, child: string): boolean {
  const childRelativeToParent = relative(parent, child);
  return (
    childRelativeToParent === "" ||
    (!childRelativeToParent.startsWith(`..${sep}`) &&
      childRelativeToParent !== ".." &&
      !isAbsolute(childRelativeToParent))
  );
}

function trustResourcePaths(cwd: string): string[] {
  const resolvedCwd = resolve(cwd);
  const userSkills = resolve(homedir(), ".agents", "skills");
  const resources: string[] = [];
  const projectPi = join(resolvedCwd, ".pi");

  if (existsSync(projectPi)) resources.push(projectPi);

  let current = resolvedCwd;
  while (true) {
    const skills = join(current, ".agents", "skills");
    if (resolve(skills) !== userSkills && existsSync(skills)) resources.push(skills);

    const parent = dirname(current);
    if (parent === current) break;
    current = parent;
  }

  return resources;
}

export async function isSafeDefaultBranch(cwd: string): Promise<boolean> {
  const insideWorkTree = await gitOutput(cwd, ["rev-parse", "--is-inside-work-tree"]);
  if (insideWorkTree !== "true") return false;

  const repoRoot = await gitOutput(cwd, ["rev-parse", "--show-toplevel"]);
  if (!repoRoot) return false;

  const branch = await gitOutput(cwd, ["symbolic-ref", "--quiet", "--short", "HEAD"]);
  if (!branch) return false;

  const remoteHead = await gitOutput(cwd, [
    "symbolic-ref",
    "--quiet",
    "--short",
    "refs/remotes/origin/HEAD",
  ]);
  if (!remoteHead?.startsWith("origin/")) return false;

  const defaultBranch = remoteHead.slice("origin/".length);
  if (branch !== defaultBranch) return false;

  const upstream = await gitOutput(cwd, [
    "rev-parse",
    "--abbrev-ref",
    "--symbolic-full-name",
    "@{upstream}",
  ]);
  if (upstream !== remoteHead) return false;

  const aheadCount = await gitOutput(cwd, ["rev-list", "--count", `${upstream}..HEAD`]);
  if (aheadCount !== "0") return false;

  const resources = trustResourcePaths(cwd);
  if (resources.some((resource) => !isWithin(repoRoot, resource))) return false;
  if (resources.length === 0) return true;

  const resourceStatus = await gitOutput(cwd, [
    "status",
    "--porcelain=v1",
    "--untracked-files=all",
    "--",
    ...resources,
  ]);

  return resourceStatus === "";
}

export default function (pi: ExtensionAPI): void {
  pi.on("project_trust", async (event, ctx): Promise<ProjectTrustEventResult> => {
    if (ctx.hasUI) return { trusted: "undecided" };

    const safeDefaultBranch = await isSafeDefaultBranch(event.cwd);
    if (!safeDefaultBranch) return { trusted: "no" };

    return { trusted: "undecided" };
  });
}
