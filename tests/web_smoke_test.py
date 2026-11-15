"""End-to-end test of the Mafqoodak WEBSITE (the PHP pages, with a browser-like session).

Fills the real forms the way a visitor and an administrator would:
register → login → lost report → (second visitor) found report with security question
→ automatic match on the dashboard → claim with answer → admin approves → admin delivers,
plus guest emergency report, admin resolves it, phone-code (OTP) login, report tracking,
and a PHP-error scan of every page visited.

Usage (XAMPP running):  python tests/web_smoke_test.py [--site http://localhost/Project/]
Only the Python standard library is used. Test data stays in the database (marked "websmoke").
"""
import argparse
import http.cookiejar
import os
import random
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PASSED, FAILED = [], []
PHP_ERROR = re.compile(r"(Fatal error|Parse error|Warning</b>|Notice</b>|Deprecated</b>|Uncaught)", re.I)


def check(name, condition, detail=""):
    (PASSED if condition else FAILED).append(name)
    print(("  PASS  " if condition else "  FAIL  ") + name + ("" if condition else "  ->  " + str(detail)[:300]))
    return condition


class Browser:
    """Keeps cookies (PHP session) and follows redirects, like a browser tab."""

    def __init__(self, site):
        self.site = site if site.endswith("/") else site + "/"
        self.jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar))

    def _open(self, req):
        try:
            with self.opener.open(req, timeout=30) as res:
                return res.status, res.geturl(), res.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            return e.code, e.geturl(), e.read().decode("utf-8", "replace")

    def get(self, page):
        status, url, html = self._open(urllib.request.Request(self.site + page))
        check("no PHP error on " + page.split("?")[0], not PHP_ERROR.search(html), PHP_ERROR.search(html))
        return status, url, html

    def post(self, page, fields, files=None):
        if files:
            boundary = uuid.uuid4().hex
            body = b""
            for k, v in fields.items():
                body += ('--%s\r\nContent-Disposition: form-data; name="%s"\r\n\r\n%s\r\n' % (boundary, k, v)).encode("utf-8")
            for k, (name, content) in files.items():
                body += ('--%s\r\nContent-Disposition: form-data; name="%s"; filename="%s"\r\nContent-Type: image/png\r\n\r\n'
                         % (boundary, k, name)).encode("utf-8") + content + b"\r\n"
            body += ("--%s--\r\n" % boundary).encode()
            req = urllib.request.Request(self.site + page, data=body,
                                         headers={"Content-Type": "multipart/form-data; boundary=" + boundary})
        else:
            req = urllib.request.Request(self.site + page, data=urllib.parse.urlencode(fields).encode("utf-8"))
        status, url, html = self._open(req)
        check("no PHP error after " + page, not PHP_ERROR.search(html), PHP_ERROR.search(html))
        return status, url, html


def flash_ok(html):
    return "alert-success" in html


def tiny_png():
    import struct, zlib
    raw = b"".join(b"\x00" + b"\x00\x80\x00" * 8 for _ in range(8))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 8, 8, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--site", default="http://localhost/Project/")
    ap.add_argument("--php", default=r"C:\xampp\php\php.exe")
    args = ap.parse_args()
    stamp = str(int(time.time()))
    pw = "WebSmoke123"
    words = ["amber", "copper", "velvet", "falcon", "harbor", "lantern", "meadow", "orchid", "pebble", "quartz",
             "saffron", "tundra", "willow", "zephyr", "cobalt", "garnet", "juniper", "marble"]
    desc = "websmoke %s %s" % (" ".join(random.sample(words, 6)), stamp)
    answer = "kiwi%d" % random.randint(100, 999)
    owner_phone = "05" + "".join(random.choice("0123456789") for _ in range(8))
    finder_phone = "05" + "".join(random.choice("0123456789") for _ in range(8))
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

    print("\n[public pages]")
    guest = Browser(args.site)
    for page in ("index.php", "login.php", "register.php", "register_admin.php", "report_emergency.php"):
        s, _, _ = guest.get(page)
        check("open " + page, s == 200, s)

    print("\n[visitor: register, login, lost report]")
    owner = Browser(args.site)
    s, url, html = owner.post("process_register.php", {"full_name": "Web Owner", "email": "websmoke.owner.%s@example.com" % stamp,
                                                       "password": pw, "confirm_password": pw, "account_type": "user", "accept_terms": "1"})
    check("register → dashboard", "user_dashboard.php" in url, url)
    s, url, html = owner.get("report_lost.php")
    category = re.search(r'<option value="([^"]+)"[^>]*>', html.split('name="item_category"')[1]).group(1) if 'name="item_category"' in html else ""
    options = re.findall(r'<option value="([^"]+)"', html.split('name="lost_location"')[1]) if 'name="lost_location"' in html else []
    check("lost form options rendered from config", category != "" and len(options) >= 2, (category, options[:3]))
    landmark = options[1] if len(options) > 1 else ""
    s, url, html = owner.post("process_lost.php", {"item_category": category, "lost_location": landmark,
                                                   "lost_date": time.strftime("%Y-%m-%d"), "item_description": desc,
                                                   "reporter_phone": owner_phone},
                              files={"item_image": ("lost.png", tiny_png())})
    check("lost report saved (success message)", "user_dashboard.php" in url and flash_ok(html), url)
    m = re.search(r"#(\d+)", html.split("alert-success", 1)[1]) if "alert-success" in html else None
    lost_id = m.group(1) if m else None
    check("report number shown", lost_id is not None, "")

    print("\n[second visitor: found report with security question]")
    finder = Browser(args.site)
    finder.post("process_register.php", {"full_name": "Web Finder", "email": "websmoke.finder.%s@example.com" % stamp,
                                         "password": pw, "confirm_password": pw, "account_type": "user", "accept_terms": "1"})
    s, url, html = finder.get("report_found.php")
    statuses = re.findall(r'<option value="([^"]+)"', html.split('name="current_status"')[1]) if 'name="current_status"' in html else []
    check("current-status options rendered", len(statuses) >= 3, statuses)
    s, url, html = finder.post("process_found.php", {"item_category": category, "found_location": landmark,
                                                     "found_date": time.strftime("%Y-%m-%d"), "item_description": desc,
                                                     "finder_phone": finder_phone, "current_status": statuses[0] if statuses else "",
                                                     "report_kind": "found", "security_question": "what is engraved?",
                                                     "security_answer": answer},
                               files={"item_image": ("found.png", tiny_png())})
    check("found report saved", "user_dashboard.php" in url and flash_ok(html), url)
    s, url, html = finder.get("report_found.php?kind=sighting")
    check("sighting mode page", s == 200 and "sighting" in html, "")

    print("\n[match → claim on the dashboard]")
    s, url, html = owner.get("user_dashboard.php")
    match_ids = re.findall(r'name="match_id" value="(\d+)"', html)
    check("suggested match listed", len(match_ids) >= 1, "")
    check("security question asked in claim form", 'name="security_answer"' in html, "")
    if match_ids:
        s, url, html = owner.post("match_action.php", {"match_id": match_ids[0], "action": "claim",
                                                       "claim_description": "engraved initials and a scratch on the back",
                                                       "security_answer": answer.upper()})
        check("claim sent", flash_ok(html), url)

    print("\n[admin: verify, approve, deliver, emergency]")
    admin_email = "websmoke.admin.%s@example.com" % stamp
    tool = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "website", "tools", "create_admin.php")
    subprocess.run([args.php, tool, "Web Admin", admin_email, pw], capture_output=True)
    admin = Browser(args.site)
    s, url, html = admin.post("process_login.php", {"email": admin_email, "password": pw, "account_type": "admin"})
    check("admin login → admin dashboard", "admin_dashboard.php" in url, url)
    s, url, html = admin.get("admin_dashboard.php")
    claim_ids = re.findall(r'name="claim_id" value="(\d+)"', html)
    check("claim visible to admin", len(claim_ids) >= 1, "")
    check("security answers shown to admin", answer in html, "")
    if claim_ids:
        newest = max(claim_ids, key=int)
        s, url, html = admin.post("claim_action.php", {"claim_id": newest, "action": "approve"})
        check("approve claim", flash_ok(html), url)

        print("\n[visitor: delivery request for the approved claim]")
        s, url, html = owner.get("user_dashboard.php")
        check("dashboard offers delivery request", "shipping_request.php?claim_id=" in html, "")
        s, url, html = owner.get("shipping_request.php?claim_id=%s" % newest)
        check("approved claim selectable for shipping", 'value="%s"' % newest in html, "")
        s, url, html = owner.post("process_shipping.php", {"claim_id": newest, "city": "Makkah", "address": "Street 1, building 2",
                                                           "phone": owner_phone, "notes": "websmoke"})
        check("delivery request saved", flash_ok(html), url)

        s, url, html = admin.get("admin_dashboard.php?ship_status=pending")
        ship_ids = re.findall(r'name="shipping_id" value="(\d+)"', html)
        check("delivery request in admin shipping panel", len(ship_ids) >= 1, "")
        if ship_ids:
            s, url, html = admin.post("admin_shipping_action.php", {"shipping_id": max(ship_ids, key=int), "status": "shipped",
                                                                   "carrier": "SMSA", "tracking_number": "WS" + stamp, "admin_note": ""})
            check("admin marks shipment as shipped", flash_ok(html) and "#panel-shipping" in url or flash_ok(html), url)
            s, url, html = owner.get("user_dashboard.php")
            check("visitor sees tracking number", "WS" + stamp in html, "")

        s, url, html = admin.post("delivery_action.php", {"claim_id": newest})
        check("mark delivered", flash_ok(html), url)
    s, url, html = owner.get("track_status.php?query=%s" % lost_id)
    check("tracking shows delivered", s == 200 and "delivered" in html, html[:200])

    s, url, html = guest.post("process_emergency.php", {"person_name": "child", "approx_age": "6", "last_seen_location": landmark,
                                                        "clothing_description": "white thobe", "reporter_phone": owner_phone})
    check("guest emergency report", s == 200 and "alert-danger" not in html, url)
    s, url, html = admin.get("admin_dashboard.php")
    em_ids = re.findall(r'name="emergency_id" value="(\d+)"', html)
    check("emergency on admin dashboard", len(em_ids) >= 1, "")
    if em_ids:
        s, url, html = admin.post("resolve_emergency.php", {"emergency_id": max(em_ids, key=int)})
        check("resolve emergency", s == 200, url)

    print("\n[admin accounts: sign-up → approval]")
    pending_email = "websmoke.pending.%s@example.com" % stamp
    s, url, html = Browser(args.site).post("process_register.php", {"full_name": "Pending Admin", "email": pending_email,
                                                                    "password": pw, "confirm_password": pw,
                                                                    "account_type": "admin", "accept_terms": "1"})
    s, url, html = admin.get("admin_dashboard.php")
    pending = re.search(r'name="admin_id" value="(\d+)"', html.split(pending_email, 1)[1]) if pending_email in html else None
    check("pending admin listed", pending is not None, "")
    if pending:
        s, url, html = admin.post("admin_accounts_action.php", {"admin_id": pending.group(1), "action": "approve"})
        check("approve admin", flash_ok(html), url)
        s, url, html = Browser(args.site).post("process_login.php", {"email": pending_email, "password": pw, "account_type": "admin"})
        check("approved admin can log in", "admin_dashboard.php" in url, url)

    print("\n[browse, map, item details]")
    for page in ("items.php", "items.php?type=found&q=websmoke", "map.php"):
        s, _, html = guest.get(page)
        check("open " + page, s == 200, s)
    s, _, html = guest.get("items.php?type=lost&q=" + urllib.parse.quote(stamp))
    check("delivered report hidden from public browsing", not re.search(r'item\.php\?type=lost&(?:amp;)?id=%s\b' % lost_id, html), "")
    s, _, html = guest.get("item.php?type=lost&id=%s" % lost_id)
    check("item details page", s == 200 and stamp in html, "")

    print("\n[visitor: profile, notifications, cancel]")
    s, url, html = owner.post("process_profile.php", {"action": "update_profile", "full_name": "Web Owner Updated",
                                                      "phone": owner_phone, "nationality": "SA"})
    check("profile updated", flash_ok(html), url)
    s, url, html = owner.get("notifications.php")
    check("notifications listed (match, claim, shipping)", s == 200 and html.count('name="notification_id"') >= 2, "")
    s, url, html = owner.post("notification_action.php", {"action": "mark_all_read"})
    check("mark all notifications read", s == 200 and "alert-danger" not in html, url)
    s, url, html = owner.post("process_lost.php", {"item_category": category, "lost_location": landmark,
                                                   "lost_date": time.strftime("%Y-%m-%d"),
                                                   "item_description": "websmoke umbrella %s" % stamp,
                                                   "reporter_phone": owner_phone})
    second = re.search(r"#(\d+)", html.split("alert-success", 1)[1]) if "alert-success" in html else None
    s, url, html = owner.get("user_dashboard.php")
    check("cancel option on dashboard", 'action="process_cancel.php"' in html, "")
    reasons = re.findall(r'name="reason"[^>]*value="([^"]+)"', html) or re.findall(r'<option value="([^"]+)"', html.split('name="reason"', 1)[1]) if 'name="reason"' in html else []
    if second and reasons:
        s, url, html = owner.post("process_cancel.php", {"lost_item_id": second.group(1), "reason": reasons[0], "details": "websmoke"})
        check("report cancelled", flash_ok(html), url)
        s, url, html = owner.get("track_status.php?query=%s" % second.group(1))
        check("tracking shows cancelled", "cancelled" in html, html[:200])
    else:
        check("cancel form has reasons", False, reasons)

    print("\n[phone-code login]")
    otp = Browser(args.site)
    s, url, html = otp.post("process_otp.php", {"action": "request", "phone": owner_phone})
    code = re.search(r"\b(\d{4})\b", html.split("alert-success", 1)[1]) if "alert-success" in html else None
    check("OTP requested (dev code shown)", code is not None, url)
    if code:
        s, url, html = otp.post("process_otp.php", {"action": "verify", "phone": owner_phone, "code": code.group(1)})
        check("OTP login → dashboard", "user_dashboard.php" in url, url)

    print("\n%d passed, %d failed" % (len(PASSED), len(FAILED)))
    return 1 if FAILED else 0


if __name__ == "__main__":
    sys.exit(main())
