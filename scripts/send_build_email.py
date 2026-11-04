#!/usr/bin/env python3
"""Email the freshly built APK to the testing team (run from Codemagic).

Required env vars (add as secure variables in Codemagic):
  SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
Optional: MAIL_FROM (defaults to SMTP_USER), MAIL_TO (comma separated).
"""
import glob
import os
import smtplib
import sys
from email.message import EmailMessage

SUBJECT = "Build from Flutter Team"

BODY = """Dear Testing Team,

Here is the new build of the Tasks (To-Do) application. Please install the attached APK and test the following:

1. Add task: tap "New task", enter a title, choose a priority and save. Try saving an empty title (an error should show).
2. Edit task: tap a task, change the title or priority and save.
3. Complete task: tick the checkbox. The title should be struck through and the progress bar should update.
4. Delete task: swipe a task to the left, then tap Undo to restore it.
5. Filters: check the All, Active and Done chips and their counts.
6. Clear completed: use the clean-up icon to remove finished tasks.
7. Persistence: close and reopen the app. Your tasks should still be there.
8. UI: check portrait/landscape and different screen sizes for any layout problems.

Build details
  Build number : {build_number}
  Branch       : {branch}
  Commit       : {commit}

Please report any bugs or UI issues with screenshots and steps to reproduce.

Thanks and regards,
Flutter Team
"""


def main() -> int:
    env = os.environ
    missing = [k for k in ("SMTP_HOST", "SMTP_PORT", "SMTP_USER", "SMTP_PASS") if not env.get(k)]
    if missing:
        print(f"Missing env vars: {', '.join(missing)}", file=sys.stderr)
        return 1

    apks = sorted(glob.glob("build/app/outputs/flutter-apk/*.apk"))
    if not apks:
        print("No APK found to attach", file=sys.stderr)
        return 1
    # Prefer arm64 (smallest common modern device build) when split per ABI.
    apk = next((a for a in apks if "arm64" in a), apks[0])

    recipients = [
        r.strip()
        for r in env.get(
            "MAIL_TO", "dhanushkumar@revolite.io,ranjanath@revolite.io"
        ).split(",")
        if r.strip()
    ]

    msg = EmailMessage()
    msg["Subject"] = SUBJECT
    msg["From"] = env.get("MAIL_FROM", env["SMTP_USER"])
    msg["To"] = ", ".join(recipients)
    msg.set_content(
        BODY.format(
            build_number=env.get("BUILD_NUMBER", "n/a"),
            branch=env.get("FCI_BRANCH", "main"),
            commit=(env.get("FCI_COMMIT", "n/a") or "n/a")[:8],
        )
    )
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
