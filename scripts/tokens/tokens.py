#!/usr/bin/env python3
"""
tokens.py — LLM token usage reporter for OpenCode + Grok

Location: ~/Code/dotfiles/scripts/tokens/tokens.py

Usage:
    python tokens.py                     # OpenCode provider summary (default)
    python tokens.py opencode            # same
    python tokens.py opencode --agents   # breakdown by agent + provider
    python tokens.py opencode --daily    # daily by provider
    python tokens.py grok                # Grok usage (best-effort from logs)
    python tokens.py all                 # both OpenCode + Grok

Environment variables (overrides):
    OPENCODE_DB      (default: ~/.local/share/opencode/opencode.db)
    GROK_LOG         (default: ~/.grok/logs/unified.jsonl)
    GROK_SESSIONS    (default: ~/.grok/sessions)
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
from collections import defaultdict
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Optional, Tuple


# ──────────────────────────────────────────────────────────────────────────────
# Paths
# ──────────────────────────────────────────────────────────────────────────────

DEFAULT_OPENCODE_DB = Path.home() / ".local" / "share" / "opencode" / "opencode.db"
DEFAULT_GROK_LOG = Path.home() / ".grok" / "logs" / "unified.jsonl"
DEFAULT_GROK_SESSIONS = Path.home() / ".grok" / "sessions"

OPENCODE_DB = Path(os.environ.get("OPENCODE_DB", DEFAULT_OPENCODE_DB))
GROK_LOG = Path(os.environ.get("GROK_LOG", DEFAULT_GROK_LOG))
GROK_SESSIONS = Path(os.environ.get("GROK_SESSIONS", DEFAULT_GROK_SESSIONS))


# ──────────────────────────────────────────────────────────────────────────────
# Formatting helpers (stdlib only)
# ──────────────────────────────────────────────────────────────────────────────

def fmt_int(n: int | None) -> str:
    if n is None:
        return "0"
    return f"{n:,}"

def fmt_cost(c: float | None) -> str:
    if c is None:
        return "$0.00"
    return f"${c:,.2f}"

def print_header(title: str) -> None:
    print(f"\n{title}")
    print("=" * len(title))

def print_table(headers: list[str], rows: list[list[Any]], col_widths: list[int] | None = None) -> None:
    """Simple aligned table using only stdlib."""
    if not rows:
        print("(no data)")
        return

    num_cols = len(headers)
    widths = col_widths or [max(len(str(h)), *(len(str(r[i])) for r in rows)) for i, h in enumerate(headers)]

    # header
    header_line = "  ".join(str(h).ljust(w) for h, w in zip(headers, widths))
    print(header_line)
    print("  ".join("-" * w for w in widths))

    # rows
    for row in rows:
        line = "  ".join(str(cell).ljust(w) for cell, w in zip(row, widths))
        print(line)


# ──────────────────────────────────────────────────────────────────────────────
# OpenCode (SQLite)
# ──────────────────────────────────────────────────────────────────────────────

def get_opencode_conn() -> sqlite3.Connection:
    if not OPENCODE_DB.exists():
        raise FileNotFoundError(f"OpenCode database not found: {OPENCODE_DB}")
    # Use uri + mode=ro for safety, but fall back to normal path if needed.
    try:
        return sqlite3.connect(f"file:{OPENCODE_DB}?mode=ro", uri=True)
    except sqlite3.OperationalError:
        return sqlite3.connect(OPENCODE_DB)

def parse_model(raw: str | None) -> tuple[str, str | None]:
    """
    Returns (provider, model_id).
    provider will be '(not recorded)' when the model column is NULL.
    """
    if raw is None:
        return "(not recorded)", None
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            provider = data.get("providerID") or "(unknown)"
            model_id = data.get("id")
            return provider, model_id
    except (json.JSONDecodeError, TypeError):
        pass
    return "(invalid)", None

def get_project_label(name: str | None, worktree: str | None) -> str:
    """Return a nice short name for a project."""
    if name and name.strip():
        return name.strip()
    if worktree:
        try:
            p = Path(worktree)
            # Handle root "/" or near-root paths gracefully
            if str(p) in {"/", ".", ""}:
                return "/"
            name_part = p.name
            if name_part:
                return name_part
            # Fall back to the last non-empty component
            parts = [x for x in p.parts if x not in {"", "/"}]
            return parts[-1] if parts else str(worktree)
        except Exception:
            return worktree or "(unknown)"
    return "(unknown project)"


def fetch_opencode_sessions(conn: sqlite3.Connection) -> list[dict[str, Any]]:
    """Load session + project data with joins."""
    cur = conn.execute("""
        SELECT
            s.id,
            s.agent,
            s.model,
            s.tokens_input,
            s.tokens_output,
            s.tokens_reasoning,
            s.tokens_cache_read,
            s.tokens_cache_write,
            s.cost,
            s.time_created,
            p.id          AS project_id,
            p.name        AS project_name,
            p.worktree    AS project_worktree
        FROM session s
        LEFT JOIN project p ON s.project_id = p.id
    """)
    rows = []
    for r in cur:
        provider, model_id = parse_model(r[2])
        project_label = get_project_label(r[11], r[12])
        rows.append({
            "id": r[0],
            "agent": r[1] or "(no agent)",
            "provider": provider,
            "model_id": model_id,
            "tokens_input": r[3] or 0,
            "tokens_output": r[4] or 0,
            "tokens_reasoning": r[5] or 0,
            "tokens_cache_read": r[6] or 0,
            "tokens_cache_write": r[7] or 0,
            "cost": r[8] or 0.0,
            "time_created": r[9],
            "project": project_label,
            "project_id": r[10],
            "project_worktree": r[12],
        })
    return rows


def parse_date_to_ms(dstr: Optional[str], end_of_day: bool = False) -> Optional[int]:
    """Convert YYYY-MM-DD to epoch milliseconds (UTC)."""
    if not dstr:
        return None
    try:
        d = date.fromisoformat(dstr.strip())
    except ValueError:
        raise ValueError(f"Invalid date '{dstr}'. Use format YYYY-MM-DD")

    if end_of_day:
        dt = datetime(d.year, d.month, d.day, 23, 59, 59, tzinfo=timezone.utc)
    else:
        dt = datetime(d.year, d.month, d.day, 0, 0, 0, tzinfo=timezone.utc)
    return int(dt.timestamp() * 1000)


def today_str() -> str:
    """Return today's date as YYYY-MM-DD (UTC)."""
    return datetime.now(timezone.utc).date().isoformat()


def filter_sessions_by_date(
    sessions: list[dict[str, Any]],
    since: Optional[str] = None,
    until: Optional[str] = None,
) -> Tuple[list[dict[str, Any]], str]:
    """Return filtered sessions + a human-readable date range label."""
    since_ms = parse_date_to_ms(since, end_of_day=False)
    until_ms = parse_date_to_ms(until, end_of_day=True)

    if not since_ms and not until_ms:
        return sessions, ""

    def in_range(s: dict[str, Any]) -> bool:
        ts = s.get("time_created") or 0
        if since_ms is not None and ts < since_ms:
            return False
        if until_ms is not None and ts > until_ms:
            return False
        return True

    filtered = [s for s in sessions if in_range(s)]

    parts = []
    if since:
        parts.append(f"from {since}")
    if until:
        parts.append(f"to {until}")
    label = " ".join(parts)
    return filtered, label

def get_provider_model(s: dict[str, Any]) -> str:
    """Return a single combined 'provider/model' label.

    Examples of desired output:
      - xai + grok-4.3                → xai/grok-4.3
      - kimi-for-coding + kimi-for-coding-highspeed → kimi-for-coding-highspeed
      - kimi-for-coding + k3          → kimi-for-coding/k3
    """
    prov = s.get("provider") or "(not recorded)"
    mid = s.get("model_id")

    if not mid:
        return prov

    # Exact duplicate (rare)
    if mid == prov:
        return prov

    pl = prov.lower()
    ml = mid.lower()

    # If model already starts with "provider/" or "provider:", just use the model
    if ml.startswith(pl + "/") or ml.startswith(pl + ":"):
        return mid

    # If model starts with the provider name directly (common for variants)
    # e.g. provider="kimi-for-coding", model_id="kimi-for-coding-highspeed"
    if ml.startswith(pl):
        # Return the model as-is (it's already the full useful name)
        return mid

    # Otherwise produce a clean combined label
    return f"{prov}/{mid}"


def opencode_provider_summary(sessions: list[dict[str, Any]], date_label: str = "") -> None:
    # The report the user requested, with provider/model as a single column.
    title = "OpenCode — tokens by provider/model"
    if date_label:
        title += f" {date_label}"
    print_header(title)

    agg: dict[str, dict[str, int | float]] = defaultdict(lambda: {
        "sessions": 0,
        "input": 0,
        "output": 0,
        "reasoning": 0,
        "cache_read": 0,
        "cache_write": 0,
        "cost": 0.0,
    })

    for s in sessions:
        key = get_provider_model(s)
        agg[key]["sessions"] += 1
        agg[key]["input"] += s["tokens_input"]
        agg[key]["output"] += s["tokens_output"]
        agg[key]["reasoning"] += s["tokens_reasoning"]
        agg[key]["cache_read"] += s["tokens_cache_read"]
        agg[key]["cache_write"] += s["tokens_cache_write"]
        agg[key]["cost"] += s["cost"]

    # Column header changed to make it clear it's now the combined value
    headers = ["provider/model", "sessions", "input", "output", "reasoning", "cache_read", "cache_write", "total", "cost"]
    rows = []

    for key in sorted(agg.keys(), key=lambda k: agg[k]["input"] + agg[k]["output"] + agg[k]["reasoning"] + agg[k]["cache_read"], reverse=True):
        a = agg[key]
        total = a["input"] + a["output"] + a["reasoning"] + a["cache_read"] + a["cache_write"]
        rows.append([
            key,
            a["sessions"],
            fmt_int(a["input"]),
            fmt_int(a["output"]),
            fmt_int(a["reasoning"]),
            fmt_int(a["cache_read"]),
            fmt_int(a["cache_write"]),
            fmt_int(total),
            fmt_cost(a["cost"]),
        ])

    print_table(headers, rows)

    # Explanation for the big "(not recorded)" bucket
    not_recorded = agg.get("(not recorded)", {})
    if not_recorded.get("sessions", 0) > 0:
        print()
        print(f"Note: {not_recorded['sessions']:,} sessions have no model/provider recorded in the DB.")
        print("      These are almost always older sessions created before OpenCode started")
        print("      storing the model field on every session row. Not sub-agents.")

def opencode_by_agent_and_provider(sessions: list[dict[str, Any]]) -> None:
    print_header("OpenCode — tokens by agent + provider")

    agg: dict[tuple[str, str], dict[str, int | float]] = defaultdict(lambda: {
        "sessions": 0, "tokens": 0, "cost": 0.0
    })

    for s in sessions:
        key = (s["agent"], s["provider"])
        agg[key]["sessions"] += 1
        total_tokens = (s["tokens_input"] + s["tokens_output"] +
                        s["tokens_reasoning"] + s["tokens_cache_read"])
        agg[key]["tokens"] += total_tokens
        agg[key]["cost"] += s["cost"]

    # Sort by total tokens desc
    sorted_items = sorted(agg.items(), key=lambda kv: kv[1]["tokens"], reverse=True)[:25]

    headers = ["agent", "provider", "sessions", "tokens"]
    rows = []
    for (agent, provider), data in sorted_items:
        rows.append([agent, provider, data["sessions"], fmt_int(data["tokens"])])

    print_table(headers, rows)


def opencode_by_project_provider_agent(sessions: list[dict[str, Any]]) -> None:
    """Tokens grouped by project, agent, provider.

    Columns: project, agent, provider
    Sorted by: project, agent, provider (case-insensitive)
    """
    print_header("OpenCode — tokens by project + agent + provider")

    agg: dict[tuple[str, str, str], dict[str, int | float]] = defaultdict(lambda: {
        "sessions": 0, "tokens": 0, "cost": 0.0
    })

    for s in sessions:
        key = (s.get("project", "(unknown)"), s["agent"], s["provider"])
        agg[key]["sessions"] += 1
        total_tokens = (s["tokens_input"] + s["tokens_output"] +
                        s["tokens_reasoning"] + s["tokens_cache_read"])
        agg[key]["tokens"] += total_tokens
        agg[key]["cost"] += s["cost"]

    # Sort strictly by (project, agent, provider) — case-insensitive
    sorted_items = sorted(
        agg.items(),
        key=lambda kv: (kv[0][0].lower(), kv[0][1].lower(), kv[0][2].lower())
    )[:100]

    headers = ["project", "agent", "provider", "sessions", "tokens"]
    rows = []
    for (project, agent, provider), data in sorted_items:
        rows.append([
            project,
            agent,
            provider,
            data["sessions"],
            fmt_int(data["tokens"]),
        ])

    print_table(headers, rows)

    projects = {s.get("project", "(unknown)") for s in sessions}
    print(f"\n({len(projects)} distinct projects in total across all data)")

def opencode_daily(sessions: list[dict[str, Any]]) -> None:
    print_header("OpenCode — daily tokens by provider (most recent)")

    daily: dict[tuple[str, str], int] = defaultdict(int)

    for s in sessions:
        if not s["time_created"]:
            continue
        # time_created is ms since epoch
        dt = datetime.fromtimestamp(s["time_created"] / 1000, tz=timezone.utc).date()
        day = dt.isoformat()
        daily[(day, s["provider"])] += (s["tokens_input"] + s["tokens_output"] +
                                        s["tokens_reasoning"] + s["tokens_cache_read"])

    # Get last ~20 rows
    sorted_days = sorted(daily.items(), key=lambda kv: kv[0][0], reverse=True)[:20]

    headers = ["day", "provider", "tokens"]
    rows = [[day, prov, fmt_int(toks)] for (day, prov), toks in sorted_days]
    print_table(headers, rows)

def cmd_opencode(args: argparse.Namespace) -> None:
    with get_opencode_conn() as conn:
        sessions = fetch_opencode_sessions(conn)

    # Resolve date filter.
    # Simple mode: --from DATE  → from DATE until today
    # Advanced mode: --since / --until
    from_date = getattr(args, "from_date", None)
    since = getattr(args, "since", None)
    until = getattr(args, "until", None)

    if from_date and not since:
        since = from_date
        if not until:
            until = today_str()

    sessions, date_label = filter_sessions_by_date(sessions, since=since, until=until)

    # Always use getattr so that bare invocation ("python tokens.py")
    # and subcommand invocation both work reliably.
    project = getattr(args, "project", False)
    agents = getattr(args, "agents", False)
    daily = getattr(args, "daily", False)

    if project:
        opencode_by_project_provider_agent(sessions)
    elif agents:
        opencode_by_agent_and_provider(sessions)
    elif daily:
        opencode_daily(sessions)
    else:
        # Default: the classic provider report
        # with columns: provider, sessions, input, output, reasoning, cache_read, cache_write, total, cost
        opencode_provider_summary(sessions, date_label)

        # Quick grand total (for the filtered set)
        total_sessions = len(sessions)
        total_tokens = sum(
            s["tokens_input"] + s["tokens_output"] + s["tokens_reasoning"] +
            s["tokens_cache_read"] + s["tokens_cache_write"]
            for s in sessions
        )
        total_cost = sum(s["cost"] for s in sessions)
        print()
        suffix = f" ({date_label})" if date_label else ""
        print(f"OpenCode totals{suffix}: {total_sessions:,} sessions | {fmt_int(total_tokens)} tokens | {fmt_cost(total_cost)}")


# ──────────────────────────────────────────────────────────────────────────────
# Grok (logs)
# ──────────────────────────────────────────────────────────────────────────────

def build_grok_sid_to_model() -> dict[str, str]:
    """Walk session events.jsonl files and map session_id → model_id."""
    mapping: dict[str, str] = {}
    if not GROK_SESSIONS.exists():
        return mapping

    for evfile in GROK_SESSIONS.rglob("events.jsonl"):
        sid = evfile.parent.name
        try:
            with evfile.open() as f:
                for line in f:
                    try:
                        e = json.loads(line)
                        if e.get("type") == "turn_started":
                            mid = e.get("model_id")
                            if mid:
                                mapping[sid] = mid
                    except Exception:
                        continue
        except Exception:
            continue
    return mapping

def cmd_grok(_args: argparse.Namespace) -> None:
    if not GROK_LOG.exists():
        raise FileNotFoundError(f"Grok log not found: {GROK_LOG}")

    print_header(f"Grok — token usage from logs (best-effort)")

    model_by_sid = build_grok_sid_to_model()

    usage: dict[str, dict[str, int]] = defaultdict(lambda: {"turns": 0, "prompt": 0, "out": 0, "reason": 0, "cached": 0})

    with GROK_LOG.open() as f:
        for line in f:
            try:
                obj = json.loads(line)
                ctx = obj.get("ctx", {})
                if ctx.get("prompt_tokens") is None:
                    continue
                sid = obj.get("sid")
                model = model_by_sid.get(sid) or ctx.get("model") or obj.get("model") or "unknown"
                usage[model]["turns"] += 1
                usage[model]["prompt"] += ctx.get("prompt_tokens") or 0
                usage[model]["out"] += ctx.get("completion_tokens") or 0
                usage[model]["reason"] += ctx.get("reasoning_tokens") or 0
                usage[model]["cached"] += ctx.get("cached_prompt_tokens") or 0
            except Exception:
                continue

    headers = ["model", "turns", "prompt", "out", "reasoning", "cached", "~total"]
    rows = []
    grand = {"turns": 0, "prompt": 0, "out": 0, "reason": 0, "cached": 0}

    for model in sorted(usage.keys()):
        u = usage[model]
        total = u["prompt"] + u["out"] + u["reason"]
        rows.append([
            model,
            u["turns"],
            fmt_int(u["prompt"]),
            fmt_int(u["out"]),
            fmt_int(u["reason"]),
            fmt_int(u["cached"]),
            fmt_int(total),
        ])
        for k in grand:
            grand[k] += u[k]

    print_table(headers, rows)

    grand_total = grand["prompt"] + grand["out"] + grand["reason"]
    print("-" * 90)
    print(f"{'GRAND TOTAL':<40} {grand['turns']:>6} "
          f"{fmt_int(grand['prompt']):>12} {fmt_int(grand['out']):>9} "
          f"{fmt_int(grand['reason']):>9} {fmt_int(grand['cached']):>12} "
          f"{fmt_int(grand_total):>12}")


# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Token usage reporter for OpenCode and Grok",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # Top-level flags so that bare "python tokens.py --project" works,
    # and also so that defaulting to "opencode" never lacks the attributes.
    p.add_argument("--agents", "-a", action="store_true",
                   help="tokens by agent + provider")
    p.add_argument("--project", "-p", action="store_true",
                   help="tokens by project + provider + agent (most detailed view)")
    p.add_argument("--daily", "-d", action="store_true",
                   help="daily tokens by provider")

    # Simple "from date" – aggregates from this date until today
    p.add_argument("--from", dest="from_date", metavar="YYYY-MM-DD",
                   help="From this date until today (e.g. --from 2026-07-11)")

    # Advanced options
    p.add_argument("--since", metavar="YYYY-MM-DD",
                   help="Include sessions from this date (inclusive)")
    p.add_argument("--until", metavar="YYYY-MM-DD",
                   help="Include sessions up to this date (inclusive)")

    # Ensure the attributes always exist
    p.set_defaults(agents=False, project=False, daily=False, from_date=None, since=None, until=None)

    sub = p.add_subparsers(dest="command")

    # opencode subcommand (re-declare the same flags for "opencode --project" style)
    oc = sub.add_parser("opencode", aliases=["oc"], help="OpenCode reports")
    oc.add_argument("--agents", "-a", action="store_true",
                    help="tokens by agent + provider")
    oc.add_argument("--project", "-p", action="store_true",
                    help="tokens by project + provider + agent (most detailed view)")
    oc.add_argument("--daily", "-d", action="store_true",
                    help="daily tokens by provider")
    oc.add_argument("--from", dest="from_date", metavar="YYYY-MM-DD",
                    help="From this date until today")
    oc.add_argument("--since", metavar="YYYY-MM-DD",
                    help="Include sessions from this date (inclusive)")
    oc.add_argument("--until", metavar="YYYY-MM-DD",
                    help="Include sessions up to this date (inclusive)")

    # grok
    sub.add_parser("grok", aliases=["g"], help="Grok usage from logs")

    # all
    sub.add_parser("all", aliases=["both"], help="OpenCode + Grok")

    p.add_argument("--help-paths", action="store_true", help="Show the database/log paths being used")
    return p

def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)

    if getattr(args, "help_paths", False):
        print("Paths used:")
        print(f"  OpenCode DB : {OPENCODE_DB}")
        print(f"  Grok log    : {GROK_LOG}")
        print(f"  Grok sessions: {GROK_SESSIONS}")
        return

    cmd = args.command or "opencode"

    try:
        if cmd in ("opencode", "oc"):
            cmd_opencode(args)
        elif cmd == "grok":
            cmd_grok(args)
        elif cmd == "all":
            try:
                # Pass through date filters + view flags
                ns = argparse.Namespace(
                    project=getattr(args, "project", False),
                    agents=getattr(args, "agents", False),
                    daily=getattr(args, "daily", False),
                    since=getattr(args, "since", None),
                    until=getattr(args, "until", None),
                )
                cmd_opencode(ns)
            except Exception as e:
                print(f"(OpenCode) {e}")
            try:
                cmd_grok(args)
            except Exception as e:
                print(f"(Grok) {e}")
        else:
            parser.print_help()
    except FileNotFoundError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Unexpected error: {e}")
        raise

if __name__ == "__main__":
    main()
