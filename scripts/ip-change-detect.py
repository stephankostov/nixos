#!/usr/bin/env python3
import os
from pathlib import Path
import urllib.request

import smtplib
from email.mime.text import MIMEText


def send_alert_email(sender, app_password, recipient, subject, body):
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = recipient

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as s:
        s.login(sender, app_password)
        s.sendmail(sender, [recipient], msg.as_string())


def read_credential(name: str) -> str:
    cred_dir = Path(os.environ["CREDENTIALS_DIRECTORY"])
    return (cred_dir / name).read_text().strip()


def get_public_ip() -> str:
    url = "https://api.ipify.org"
    with urllib.request.urlopen(url, timeout=10) as resp:
        return resp.read().decode("utf-8").strip()


def main():
    to_addr = "stephank179@gmail.com"

    state_file = Path.home() / ".cache" / "ipwatch_last_ip"
    state_file.parent.mkdir(parents=True, exist_ok=True)

    ip = get_public_ip()

    try:
        old_ip = state_file.read_text().strip()
    except FileNotFoundError:
        old_ip = ""

    if ip != old_ip:
        state_file.write_text(ip + "\n")
        body = f"virgin mary! she's changed our coordinates again!! new public ip: {ip}\n"
        send_alert_email(
            sender="stephhacks1337@gmail.com",
            app_password=read_credential("smpt_gmail_app_password"),
            recipient=to_addr,
            subject="home ip has changed",
            body=body,
        )


if __name__ == "__main__":
    main()