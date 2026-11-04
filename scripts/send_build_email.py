#!/usr/bin/env python3
"""Email the freshly built APK to the testing team (run from Codemagic).

The email content lives in codemagic.yaml (MAIL_SUBJECT, MAIL_BODY, MAIL_TO).
Required secure env vars: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
Optional: MAIL_FROM (defaults to SMTP_USER).
"""
import glob
import os
import smtplib
import sys
from email.message import EmailMessage


def main() -> int:
    env = os.environ
    required = ("SMTP_HOST", "SMTP_PORT", "SMTP_USER", "SMTP_PASS", "MAIL_TO",
                "MAIL_SUBJECT", "MAIL_BODY")
    missing = [k for k in required if not env.get(k)]
    if missing:
        print(f"Missing env vars: {', '.join(missing)}", file=sys.stderr)
        return 1

    apks = sorted(glob.glob("build/app/outputs/flutter-apk/*.apk"))
    if not apks:
        print("No APK found to attach", file=sys.stderr)
        return 1
    apk = next((a for a in apks if "arm64" in a), apks[0])

    recipients = [r.strip() for r in env["MAIL_TO"].split(",") if r.strip()]

    details = (
        "\n\nBuild details\n"
        f"  Build number : {env.get('BUILD_NUMBER', 'n/a')}\n"
        f"  Branch       : {env.get('FCI_BRANCH', 'main')}\n"
        f"  Commit       : {(env.get('FCI_COMMIT') or 'n/a')[:8]}\n"
    )

    msg = EmailMessage()
    msg["Subject"] = env["MAIL_SUBJECT"]
    msg["From"] = env.get("MAIL_FROM", env["SMTP_USER"])
    msg["To"] = ", ".join(recipients)
    msg.set_content(env["MAIL_BODY"].rstrip() + details)
    with open(apk, "rb") as f:
        msg.add_attachment(
            f.read(),
            maintype="application",
            subtype="vnd.android.package-archive",
            filename=os.path.basename(apk),
        )

    with smtplib.SMTP(env["SMTP_HOST"], int(env["SMTP_PORT"])) as s:
        s.starttls()
        s.login(env["SMTP_USER"], env["SMTP_PASS"])
        s.send_message(msg)
    print(f"Sent {os.path.basename(apk)} to {', '.join(recipients)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
