"""End-to-end test of the Mafqoodak API (docs/API.md).

Runs the whole life cycle against a running server with fresh accounts:
sign-up → login → profile → OTP → lost + found reports (photo, security question)
→ automatic match → claim → admin approval → shipping → delivery → notifications,
plus emergency, cancel, tracking, browse, map and permission checks.

Usage (XAMPP running):
    python tests/api_smoke_test.py
    python tests/api_smoke_test.py --base http://localhost/Project/api/v1/ --php C:/xampp/php/php.exe

Only the Python standard library is used. Test data stays in the database (marked "smoke").
"""
import argparse
import json
import os
import random
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid
import zlib

PASSED, FAILED = [], []
ANSWER = "zebra-%d" % random.randint(1000, 9999)   # finder's secret answer

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def tiny_png():
    """A valid 8x8 red PNG (no image library needed)."""
    raw = b"".join(b"\x00" + b"\xc8\x00\x00" * 8 for _ in range(8))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 8, 8, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class Api:
    def __init__(self, base, lang="ar"):
        self.base = base if base.endswith("/") else base + "/"
        self.lang = lang

    def call(self, method, path, token=None, body=None, fields=None, files=None):
        headers = {"Accept": "application/json", "Accept-Language": self.lang}
        data = None
        if token:
            headers["Authorization"] = "Bearer " + token
        if fields is not None or files:
            boundary = uuid.uuid4().hex
            parts = []
            for k, v in (fields or {}).items():
                parts.append(('--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n' % (boundary, k, v)).encode("utf-8"))
            for k, (name, content) in (files or {}).items():
                parts.append(('--%s\r\nContent-Disposition: form-data; name="%s"; filename="%s"\r\nContent-Type: image/png\r\n\r\n'
                              % (boundary, k, name)).encode("utf-8") + content + b"\r\n")
            parts.append(("--%s--\r\n" % boundary).encode())
            data = b"".join(parts)
            headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
        elif body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(self.base + path, data=data, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=30) as res:
                return res.status, json.loads(res.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read().decode("utf-8"))


def check(name, condition, detail=""):
    (PASSED if condition else FAILED).append(name)
    print(("  PASS  " if condition else "  FAIL  ") + name + ("" if condition else "  ->  " + str(detail)[:300]))
    return condition


def phone():
    return "05" + "".join(random.choice("0123456789") for _ in range(8))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://localhost/Project/api/v1/")
    ap.add_argument("--php", default=r"C:\xampp\php\php.exe", help="PHP CLI used to create a test admin")
    args = ap.parse_args()
    api = Api(args.base)
    stamp = str(int(time.time()))
    pw = "Smoke12345"
    owner_email, finder_email, admin_email = ("smoke.owner.%s@example.com" % stamp,
                                              "smoke.finder.%s@example.com" % stamp,
                                              "smoke.admin.%s@example.com" % stamp)
    owner_phone, finder_phone = phone(), phone()

    print("\n[public]")
    s, r = api.call("GET", "health")
    check("health", s == 200 and r["ok"], r)
    s, r = api.call("GET", "lookups")
    check("lookups", s == 200 and len(r["data"]["categories"]) >= 1 and len(r["data"]["landmarks"]) >= 2, r)
    lookups = r["data"]
    category, landmark = lookups["categories"][1], lookups["landmarks"][1]["name"]
    s, r = api.call("GET", "nope")
    check("unknown route -> 404", s == 404, r)

    print("\n[accounts]")
    s, r = api.call("POST", "auth/register", body={"full_name": "", "email": "bad", "password": "1"})
    check("register validation -> 422 with fields", s == 422 and "email" in r["error"].get("fields", {}), r)
    tokens = {}
    for who, email in (("owner", owner_email), ("finder", finder_email)):
        s, r = api.call("POST", "auth/register", body={"full_name": "Smoke " + who, "email": email,
                                                        "password": pw, "confirm_password": pw})
        check("register " + who, s == 201 and r["data"]["token"], r)
        tokens[who] = r["data"]["token"]
    s, r = api.call("POST", "auth/register", body={"full_name": "x", "email": owner_email, "password": pw, "confirm_password": pw})
    check("duplicate email -> 409", s == 409, r)
    s, r = api.call("POST", "auth/login", body={"email": owner_email, "password": "wrong", "account_type": "user"})
    check("wrong password -> 401", s == 401, r)
    s, r = Api(args.base, "en").call("POST", "auth/login", body={"email": owner_email, "password": "wrong", "account_type": "user"})
    check("English message with Accept-Language: en", s == 401 and r["error"]["message"].isascii(), r)
    s, r = api.call("PUT", "me", tokens["owner"], body={"full_name": "Smoke owner", "phone": owner_phone, "nationality": "SA"})
    check("update profile", s == 200 and r["data"]["user"]["phone"] == owner_phone, r)
    s, r = api.call("PUT", "me", tokens["finder"], body={"full_name": "Smoke finder", "phone": finder_phone})
    check("update finder phone", s == 200, r)
    s, r = api.call("POST", "auth/otp/request", body={"phone": owner_phone})
    code = r.get("data", {}).get("debug_code")
    check("otp request (dev code)", s == 200 and code, r)
    s, r = api.call("POST", "auth/otp/verify", body={"phone": owner_phone, "code": "0000" if code != "0000" else "1111"})
    check("otp wrong code -> 401", s == 401, r)
    s, r = api.call("POST", "auth/otp/verify", body={"phone": owner_phone, "code": code})
    check("otp login", s == 200 and r["data"]["role"] == "user", r)
    s, r = api.call("POST", "me/password", tokens["owner"], body={"current_password": pw, "new_password": pw})
    check("change password", s == 200, r)

    print("\n[reports]")
    words = ["amber", "copper", "velvet", "falcon", "harbor", "lantern", "meadow", "orchid", "pebble", "quartz",
             "saffron", "tundra", "willow", "zephyr", "cobalt", "garnet", "juniper", "marble", "nectar", "onyx"]
    desc = "smoke %s %s" % (" ".join(random.sample(words, 6)), stamp)   # unique wording per run
    s, r = api.call("POST", "reports/lost", tokens["owner"], fields={
        "item_category": category, "lost_location": landmark, "lost_date": time.strftime("%Y-%m-%d"),
        "item_description": desc, "reporter_phone": owner_phone}, files={"image": ("lost.png", tiny_png())})
    check("lost report with photo", s == 201, r)
    lost_id = r.get("data", {}).get("id")
    s, r = api.call("POST", "reports/found", tokens["finder"], fields={
        "item_category": category, "found_location": landmark, "found_date": time.strftime("%Y-%m-%d"),
        "item_description": desc, "finder_phone": finder_phone, "current_status": lookups["found_current_statuses"][0],
        "security_question": "cover colour?", "security_answer": ANSWER}, files={"image": ("found.png", tiny_png())})
    check("found report with security question", s == 201 and r["data"]["matches_found"] >= 1, r)
    found_id = r.get("data", {}).get("id")
    s, r = api.call("POST", "reports/found", tokens["finder"], fields={"item_category": ""})
    check("found validation -> 422", s == 422, r)
    s, r = api.call("POST", "reports/found", tokens["finder"], fields={
        "item_category": category, "found_location": landmark, "found_date": time.strftime("%Y-%m-%d"),
        "item_description": "smoke sighting %s" % stamp, "finder_phone": finder_phone,
        "current_status": lookups["found_current_statuses"][-1], "report_kind": "sighting"})
    check("sighting report", s == 201, r)
    s, r = api.call("GET", "reports/mine", tokens["owner"])
    check("my reports", s == 200 and any(i["id"] == lost_id for i in r["data"]["lost"]), r)
    s, r = api.call("GET", "track/%s" % lost_id)
    check("track report", s == 200 and r["data"]["status"] == "matched", r)
    s, r = api.call("POST", "emergencies", fields={"approx_age": "7", "last_seen_location": landmark,
                                                   "clothing_description": "white thobe", "reporter_phone": owner_phone})
    check("guest emergency report", s == 201, r)
    emergency_id = r.get("data", {}).get("id")

    print("\n[items + matching]")
    s, r = api.call("GET", "items?type=found&q=" + urllib.request.quote(stamp))
    check("browse found items", s == 200 and any(i["id"] == found_id for i in r["data"]["items"]), r)
    s, r = api.call("GET", "items/found/%s" % found_id)
    check("details: question shown, answer hidden", s == 200 and r["data"]["security_question"] == "cover colour?"
          and ANSWER not in json.dumps(r["data"]) and r["data"]["images"], r)
    s, r = api.call("GET", "map/items")
    check("map items", s == 200, r)
    s, r = api.call("GET", "matches", tokens["owner"])
    match = next((m for m in r["data"]["matches"] if m["found"]["id"] == found_id), None) if s == 200 else None
    check("automatic match suggested", match is not None, r)
    s, r = api.call("POST", "items/found/%s/claim" % found_id, tokens["finder"],
                    body={"claim_description": "this is my own report"})
    check("finder cannot claim own item -> 403", s == 403, r)
    s, r = api.call("POST", "matches/%s/claim" % match["match_id"], tokens["owner"],
                    body={"claim_description": "black phone, red cover, scratch on back", "security_answer": ANSWER.upper()})
    check("claim via match", s == 201, r)
    claim_id = r.get("data", {}).get("claim_id")
    s, r = api.call("POST", "items/found/%s/claim" % found_id, tokens["owner"],
                    body={"claim_description": "black phone, red cover, scratch on back"})
    check("duplicate claim -> 409", s == 409, r)
    s, r = api.call("POST", "shipping", tokens["owner"], body={"claim_id": claim_id, "city": "Makkah",
                                                               "address": "Street 1", "phone": owner_phone})
    check("shipping before approval refused", s in (404, 409, 422), r)

    print("\n[admin]")
    s, r = api.call("GET", "admin/stats", tokens["owner"])
    check("user cannot call admin routes -> 403", s == 403, r)
    tool = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "website", "tools", "create_admin.php")
    out = subprocess.run([args.php, tool, "Smoke Admin", admin_email, pw], capture_output=True, text=True)
    check("create admin with tools/create_admin.php", out.returncode == 0, out.stderr or out.stdout)
    s, r = api.call("POST", "auth/login", body={"email": admin_email, "password": pw, "account_type": "admin"})
    check("admin login", s == 200 and r["data"]["role"] == "admin", r)
    admin = r.get("data", {}).get("token")
    s, r = api.call("GET", "admin/stats", admin)
    check("admin stats", s == 200 and r["data"]["total_lost"] >= 1 and "heat_points" in r["data"], r)
    s, r = api.call("GET", "admin/claims", admin)
    review = next((c for c in r["data"]["claims"] if c["claim_id"] == claim_id), None) if s == 200 else None
    check("claim in verification list with Q/A", review is not None and review["correct_answer"] == ANSWER
          and review["security_answer"] == ANSWER.upper(), r)
    s, r = api.call("POST", "admin/claims/%s/approve" % claim_id, admin)
    check("approve claim", s == 200, r)
    s, r = api.call("POST", "shipping", tokens["owner"], body={"claim_id": claim_id, "city": "Makkah",
                                                               "address": "Street 1", "phone": owner_phone})
    check("request shipping after approval", s == 201, r)
    shipping_id = r.get("data", {}).get("shipping_id")
    s, r = api.call("POST", "admin/shipping/%s" % shipping_id, admin,
                    body={"status": "shipped", "carrier": "SMSA", "tracking_number": "TRK%s" % stamp})
    check("admin updates shipping", s == 200, r)
    s, r = api.call("GET", "shipping/mine", tokens["owner"])
    check("user sees shipping status", s == 200 and any(x["status"] == "shipped" for x in r["data"]["requests"]), r)
    s, r = api.call("POST", "admin/claims/%s/deliver" % claim_id, admin)
    check("mark delivered", s == 200, r)
    s, r = api.call("GET", "track/%s" % lost_id)
    check("lost report now delivered", s == 200 and r["data"]["status"] == "delivered", r)
    s, r = api.call("GET", "admin/emergencies", admin)
    check("admin emergencies list", s == 200 and any(e["id"] == emergency_id for e in r["data"]["emergencies"]), r)
    s, r = api.call("POST", "admin/emergencies/%s/resolve" % emergency_id, admin)
    check("resolve emergency", s == 200, r)
    s, r = api.call("GET", "admin/reports?type=lost", admin)
    check("admin reports with reporter", s == 200 and any(x.get("reporter") for x in r["data"]["reports"]), r)
    s, r = api.call("GET", "admin/open-items", admin)
    check("admin open items", s == 200 and "lost" in r["data"] and "found" in r["data"], r)
    s, r = api.call("POST", "auth/register-admin", body={"full_name": "Pending", "email": "smoke.pending.%s@example.com" % stamp,
                                                          "password": pw, "confirm_password": pw})
    check("admin sign-up is pending", s == 201, r)
    s, r = api.call("GET", "admin/admins/pending", admin)
    pending = [a for a in r["data"]["admins"] if a["email"].startswith("smoke.pending.%s" % stamp)] if s == 200 else []
    check("pending admin listed", len(pending) == 1, r)
    if pending:
        s, r = api.call("POST", "admin/admins/%s/approve" % pending[0]["admin_id"], admin)
        check("approve admin", s == 200, r)

    print("\n[notifications + cancel]")
    s, r = api.call("GET", "notifications", tokens["owner"])
    types = {n["notification_type"] for n in r["data"]["notifications"]} if s == 200 else set()
    check("owner notified (match, claim, shipping)", {"match", "claim", "shipping"} <= types, types)
    s, r = api.call("POST", "notifications/read-all", tokens["owner"])
    check("mark all read", s == 200, r)
    s, r = api.call("POST", "reports/lost", tokens["owner"], fields={
        "item_category": lookups["categories"][0], "lost_location": landmark, "lost_date": time.strftime("%Y-%m-%d"),
        "item_description": "smoke passport %s" % stamp, "reporter_phone": owner_phone})
    second = r.get("data", {}).get("id")
    s, r = api.call("POST", "reports/lost/%s/cancel" % second, tokens["owner"],
                    body={"reason": lookups["cancel_reasons"][1], "details": "smoke"})
    check("cancel a report with reason", s == 200, r)
    s, r = api.call("POST", "auth/logout", tokens["finder"])
    s2, r2 = api.call("GET", "me", tokens["finder"])
    check("logout revokes token", s == 200 and s2 == 401, r2)

    print("\n%d passed, %d failed" % (len(PASSED), len(FAILED)))
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
