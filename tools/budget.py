#!/usr/bin/env python3
"""Token meter for the CatBudget assessment.

Reads the Claude Code session transcripts for a project directory and reports
weighted token spend against the cap.

Weighted tokens mirror API price ratios, so a long unmanaged context costs real
budget and `/clear` genuinely saves it:

    uncached input  x 1
    cache write     x 1.25
    cache read      x 0.1
    output          x 5

Usage:
    python3 tools/budget.py --project-dir /path/to/starter
    python3 tools/budget.py --project-dir . --since 2026-09-09T14:00:00
    python3 tools/budget.py --project-dir . --cap 1500000 --json
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

WEIGHTS = {"input": 1.0, "cache_write": 1.25, "cache_read": 0.1, "output": 5.0}
DEFAULT_CAP = 1_500_000
PROJECTS_ROOT = Path.home() / ".claude" / "projects"


def encoded_name(project_dir: Path) -> str:
    return re.sub(r"[^A-Za-z0-9]", "-", str(project_dir))


def session_dir(project_dir: Path) -> Path | None:
    """Locate the transcript directory, by name first then by recorded cwd."""
    direct = PROJECTS_ROOT / encoded_name(project_dir)
    if direct.is_dir():
        return direct

    target = str(project_dir)
    for candidate in PROJECTS_ROOT.glob("*/"):
        for transcript in candidate.glob("*.jsonl"):
            try:
                with transcript.open() as handle:
                    for line in handle:
                        record = json.loads(line)
                        if record.get("cwd") == target:
                            return candidate
                        break
            except (OSError, json.JSONDecodeError):
                continue
    return None


def parse_since(value: str | None) -> datetime | None:
    if not value:
        return None
    text = value.replace("Z", "+00:00")
    stamp = datetime.fromisoformat(text)
    if stamp.tzinfo is None:
        stamp = stamp.astimezone()
    return stamp.astimezone(timezone.utc)


def record_time(record: dict) -> datetime | None:
    stamp = record.get("timestamp")
    if not stamp:
        return None
    try:
        return datetime.fromisoformat(stamp.replace("Z", "+00:00")).astimezone(timezone.utc)
    except ValueError:
        return None


def is_human_prompt(record: dict) -> bool:
    """A typed prompt, as opposed to a tool result echoed back as a user turn."""
    if record.get("type") != "user" or record.get("isMeta"):
        return False
    content = record.get("message", {}).get("content")
    if isinstance(content, str):
        return bool(content.strip())
    if isinstance(content, list):
        return any(
            block.get("type") == "text" and block.get("text", "").strip()
            for block in content
            if isinstance(block, dict)
        )
    return False


def collect(directory: Path, since: datetime | None) -> dict:
    totals = {"input": 0, "cache_write": 0, "cache_read": 0, "output": 0}
    prompt_ids: set[str] = set()
    stats = {
        "prompts": 0,
        "assistant_turns": 0,
        "sessions": 0,
        "compactions": 0,
        "subagent_turns": 0,
        "subagent_weighted": 0.0,
        "models": set(),
        "first": None,
        "last": None,
    }

    for transcript in sorted(directory.glob("*.jsonl")):
        counted_session = False
        with transcript.open() as handle:
            for line in handle:
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    continue

                when = record_time(record)
                if since and when and when < since:
                    continue

                if when:
                    stats["first"] = min(filter(None, [stats["first"], when]))
                    stats["last"] = max(filter(None, [stats["last"], when]))

                if not counted_session:
                    stats["sessions"] += 1
                    counted_session = True

                kind = record.get("type")

                if kind == "assistant":
                    message = record.get("message", {})
                    usage = message.get("usage") or {}
                    if not usage:
                        continue
                    turn = {
                        "input": usage.get("input_tokens", 0),
                        "cache_write": usage.get("cache_creation_input_tokens", 0),
                        "cache_read": usage.get("cache_read_input_tokens", 0),
                        "output": usage.get("output_tokens", 0),
                    }
                    for key, value in turn.items():
                        totals[key] += value
                    stats["assistant_turns"] += 1
                    if message.get("model"):
                        stats["models"].add(message["model"])
                    if record.get("isSidechain"):
                        stats["subagent_turns"] += 1
                        stats["subagent_weighted"] += sum(
                            turn[k] * WEIGHTS[k] for k in turn
                        )

                elif is_human_prompt(record):
                    # promptId is authoritative and survives queued prompts;
                    # fall back to counting turns when it is absent.
                    identifier = record.get("promptId")
                    if identifier:
                        prompt_ids.add(identifier)
                    else:
                        stats["prompts"] += 1

                elif kind == "system" and record.get("subtype") == "compact_boundary":
                    stats["compactions"] += 1

                if record.get("isCompactSummary"):
                    stats["compactions"] += 1

    stats["prompts"] += len(prompt_ids)
    weighted = sum(totals[key] * WEIGHTS[key] for key in totals)
    return {"totals": totals, "weighted": weighted, "stats": stats}


def render(result: dict, cap: int) -> str:
    totals = result["totals"]
    stats = result["stats"]
    weighted = result["weighted"]
    pct = (weighted / cap * 100) if cap else 0

    raw_input = totals["input"] + totals["cache_write"] + totals["cache_read"]
    ratio = (totals["output"] / raw_input) if raw_input else 0

    filled = int(min(pct, 100) // 5)
    bar = "#" * filled + "." * (20 - filled)

    elapsed = ""
    if stats["first"] and stats["last"]:
        minutes = (stats["last"] - stats["first"]).total_seconds() / 60
        elapsed = f"{minutes:.0f} min"

    lines = [
        "",
        "  CatBudget token meter",
        "  " + "-" * 44,
        f"  uncached input   {totals['input']:>12,}  x1",
        f"  cache write      {totals['cache_write']:>12,}  x1.25",
        f"  cache read       {totals['cache_read']:>12,}  x0.1",
        f"  output           {totals['output']:>12,}  x5",
        "  " + "-" * 44,
        f"  WEIGHTED         {weighted:>12,.0f}  of {cap:,}",
        f"  [{bar}] {pct:.1f}%",
        "",
        f"  prompts          {stats['prompts']:>12,}",
        f"  assistant turns  {stats['assistant_turns']:>12,}",
        f"  sessions/clears  {stats['sessions']:>12,}",
        f"  compactions      {stats['compactions']:>12,}",
        f"  subagent turns   {stats['subagent_turns']:>12,}"
        + (f"  ({stats['subagent_weighted']:,.0f} weighted)" if stats["subagent_turns"] else ""),
        f"  output:input     {ratio:>12.3f}",
    ]
    if elapsed:
        lines.append(f"  elapsed          {elapsed:>12}")
    if stats["models"]:
        lines.append(f"  models           {', '.join(sorted(stats['models'])):>12}")
    lines.append("")

    if weighted > cap:
        lines.append("  OVER BUDGET. The session ends here.")
        lines.append("")
    elif pct > 80:
        lines.append(f"  {cap - weighted:,.0f} weighted tokens left.")
        lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Token meter for the CatBudget assessment.")
    parser.add_argument("--project-dir", default=os.getcwd())
    parser.add_argument("--since", help="ISO timestamp; ignore activity before this")
    parser.add_argument("--cap", type=int, default=DEFAULT_CAP)
    parser.add_argument("--json", action="store_true", dest="as_json")
    args = parser.parse_args()

    project_dir = Path(args.project_dir).expanduser().resolve()
    directory = session_dir(project_dir)

    if directory is None:
        # Normal at the start of a session: nothing has been spent yet.
        print(f"\n  No Claude Code transcripts yet for {project_dir}")
        print("  Nothing spent. The meter starts counting at your first prompt.\n")
        return 0

    result = collect(directory, parse_since(args.since))

    if args.as_json:
        payload = {
            "weighted": round(result["weighted"]),
            "cap": args.cap,
            "totals": result["totals"],
            "prompts": result["stats"]["prompts"],
            "assistant_turns": result["stats"]["assistant_turns"],
            "sessions": result["stats"]["sessions"],
            "compactions": result["stats"]["compactions"],
            "subagent_turns": result["stats"]["subagent_turns"],
            "models": sorted(result["stats"]["models"]),
        }
        print(json.dumps(payload, indent=2))
    else:
        print(render(result, args.cap))

    return 1 if result["weighted"] > args.cap else 0


if __name__ == "__main__":
    sys.exit(main())
