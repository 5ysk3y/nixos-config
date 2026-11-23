"""Fill or copy Bitwarden logins in qutebrowser, through rbw.

qute-rbw [--copy] [--pick] [MODE]

MODE is what to fill or copy for the current site:
  login     username and password (the default). With a TOTP secret, the
            code also goes on the clipboard, for the next page.
  username  only the username
  password  only the password
  totp      only the current TOTP code

It finds the logins whose saved URIs match the page's site, the way
Bitwarden matches them by default: the same base domain, so a login for
github.com also matches gist.github.com. One match is used straight away;
several, or --pick, open a picker. With no match it offers every login.

Values are filled through qutebrowser's JavaScript, not typed as keys.
With --copy they go on the clipboard instead, and are cleared again after
a while if the clipboard still holds them.

The tool paths below are filled in by Nix (features/apps/qutebrowser).
"""

import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.parse

from publicsuffixlist import PublicSuffixList

RBW = "@rbw@"
FILL_JS = "@fillJs@"
# A picker that reads one entry per line and prints the chosen line's index
PICKER = json.loads("""@picker@""")
CLIP_COPY = json.loads("""@clipCopy@""")
CLIP_PASTE = json.loads("""@clipPaste@""")
CLIP_CLEAR = json.loads("""@clipClear@""")
# Run after the vault is unlocked here, so status bars can update at once
ON_UNLOCK = json.loads("""@onUnlock@""")

# Seconds a copied secret stays on the clipboard. A TOTP code changes
# every 30 seconds anyway.
CLEAR_AFTER = {"username": 0, "password": 30, "totp": 45}

PSL = PublicSuffixList()


class Qute:
    """Sends commands to the qutebrowser that started this script."""

    def __init__(self):
        self.fifo = os.environ.get("QUTE_FIFO")

    def send(self, command):
        if not self.fifo:
            print(command)
            return
        with open(self.fifo, "a", encoding="utf-8") as f:
            f.write(command + "\n")

    def _message(self, level, text):
        # Messages pass through qutebrowser's command parser, which splits
        # on ";;", expands {url} and friends, and reads quotes. Entry names
        # could hold any of them.
        for old, new in ((";;", "; ;"), ("{", "("), ("}", ")"), ("'", "’"), ("\n", " ")):
            text = text.replace(old, new)
        self.send(f"message-{level} '{text}'")

    def info(self, text):
        self._message("info", text)

    def error(self, text):
        self._message("error", text)

    def jseval(self, code):
        # The whole snippet goes base64-encoded. It then holds no ";;",
        # no {url}-style variable and no newline for qutebrowser to act on.
        # jseval runs it in its own JS world and shows what it returns.
        encoded = base64.b64encode(code.encode("utf-8")).decode("ascii")
        self.send(f'jseval eval(atob("{encoded}"))')


class Fail(Exception):
    """An error to show in qutebrowser, ending the script."""


def rbw(*args, check=True):
    result = subprocess.run(
        [RBW, *args], capture_output=True, text=True, check=False
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip().splitlines()
        raise Fail(f"rbw {args[0]} failed: {detail[-1] if detail else ''}")
    return result


def ensure_unlocked():
    if rbw("unlocked", check=False).returncode == 0:
        return
    # rbw-agent shows the pinentry dialog set in rbw's config
    if rbw("unlock", check=False).returncode != 0:
        raise Fail("the vault is still locked")
    if ON_UNLOCK:
        subprocess.run(ON_UNLOCK, check=False, capture_output=True)


def uri_host(uri):
    """The host name in a saved URI. Bitwarden allows a bare domain."""
    if "://" not in uri:
        uri = "//" + uri
    try:
        return (urllib.parse.urlsplit(uri).hostname or "").rstrip(".")
    except ValueError:
        return ""


def base_domain(host):
    # None for hosts with no registrable domain: IP addresses, localhost,
    # single-label names on a home network
    return PSL.privatesuffix(host)


def match_rank(page_host, entry_host):
    """How well a saved host matches the page: lower is better, or None."""
    if not entry_host:
        return None
    if entry_host == page_host:
        return 0
    if page_host.endswith("." + entry_host):
        return 1
    page_base = base_domain(page_host)
    if page_base and page_base == base_domain(entry_host):
        return 2
    return None


def matching_logins(logins, page_host):
    ranked = []
    for entry in logins:
        ranks = [
            r
            for r in (match_rank(page_host, uri_host(u)) for u in entry.get("uris") or [])
            if r is not None
        ]
        if ranks:
            ranked.append((min(ranks), entry))
    ranked.sort(key=lambda r: (r[0], label(r[1]).lower()))
    return [entry for _, entry in ranked]


def label(entry):
    parts = [entry.get("name") or "(no name)"]
    if entry.get("user"):
        parts.append(entry["user"])
    if entry.get("folder"):
        parts.append(f"[{entry['folder']}]")
    return "  ·  ".join(" ".join(p.split()) for p in parts)


def pick(entries):
    lines = "\n".join(label(e) for e in entries) + "\n"
    result = subprocess.run(
        PICKER, input=lines, capture_output=True, text=True, check=False
    )
    choice = result.stdout.strip()
    if result.returncode != 0 or not choice.lstrip("-").isdigit():
        return None
    index = int(choice)
    return entries[index] if 0 <= index < len(entries) else None


def clipboard_holds(value):
    result = subprocess.run(
        CLIP_PASTE, capture_output=True, text=True, check=False
    )
    return result.stdout.rstrip("\n") == value


def copy(value, clear_after):
    subprocess.run(CLIP_COPY, input=value, text=True, check=True)
    if not clear_after:
        return
    # Clear it later from a detached child, so qutebrowser isn't kept
    # waiting. Only if it is still ours: a newer copy is left alone.
    if os.fork() != 0:
        return
    os.setsid()
    devnull = os.open(os.devnull, os.O_RDWR)
    for fd in (0, 1, 2):
        os.dup2(devnull, fd)
    time.sleep(clear_after)
    if clipboard_holds(value):
        subprocess.run(CLIP_CLEAR, stdin=subprocess.DEVNULL, check=False)
    os._exit(0)


def parse_args():
    parser = argparse.ArgumentParser(
        prog="qute-rbw",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "mode",
        nargs="?",
        default="login",
        choices=["login", "username", "password", "totp"],
    )
    parser.add_argument(
        "--copy",
        action="store_true",
        help="copy to the clipboard instead of filling the page",
    )
    parser.add_argument(
        "--pick",
        action="store_true",
        help="always open the picker, even with one match",
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("QUTE_URL", ""),
        help="the page to match (default: the current page)",
    )
    return parser.parse_args()


def run(args, qute):
    if args.copy and args.mode == "login":
        raise Fail("--copy needs one field: username, password or totp")

    host = uri_host(args.url)
    ensure_unlocked()

    logins = [
        e for e in json.loads(rbw("list", "--raw").stdout) if e.get("type") == "Login"
    ]
    matches = matching_logins(logins, host) if host else []
    candidates = matches or logins
    if not candidates:
        raise Fail("the vault has no logins")

    if len(matches) == 1 and not args.pick:
        entry = matches[0]
    else:
        if not matches:
            qute.info(f"rbw: no login saved for {host or 'this page'}, choose from all")
        entry = pick(candidates)
        if entry is None:
            return

    data = json.loads(rbw("get", "--raw", entry["id"]).stdout).get("data") or {}
    values = {"username": data.get("username"), "password": data.get("password")}
    has_totp = bool(data.get("totp"))
    if args.mode == "totp":
        if not has_totp:
            raise Fail(f"{entry.get('name')} has no TOTP secret")
        values["totp"] = rbw("code", entry["id"]).stdout.strip()

    if args.copy:
        value = values.get(args.mode)
        if not value:
            raise Fail(f"{entry.get('name')} has no {args.mode}")
        copy(value, CLEAR_AFTER[args.mode])
        wait = CLEAR_AFTER[args.mode]
        clearing = f", clearing it in {wait}s" if wait else ""
        qute.info(f"rbw: copied the {args.mode} for {entry.get('name')}{clearing}")
        return

    payload = json.dumps(
        {"host": host, "mode": args.mode, "name": entry.get("name") or "", **values}
    )
    with open(FILL_JS, encoding="utf-8") as f:
        code = f.read().replace(
            "__PAYLOAD__", base64.b64encode(payload.encode("utf-8")).decode("ascii")
        )
    qute.jseval(code)

    # The 2FA page usually comes next. Have the code ready to paste.
    if args.mode == "login" and has_totp:
        copy(rbw("code", entry["id"]).stdout.strip(), CLEAR_AFTER["totp"])
        qute.info("rbw: TOTP code copied for the next step")


def main():
    args = parse_args()
    qute = Qute()
    try:
        run(args, qute)
    except Fail as e:
        qute.error(f"rbw: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
