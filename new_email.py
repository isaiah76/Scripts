import imaplib
import os
from dotenv import load_dotenv

load_dotenv()

imap_server = "imap.gmail.com"

accounts = [
    {"email": os.getenv("EMAIL_USER1"), "password": os.getenv("EMAIL_PASS1")},
    {"email": os.getenv("EMAIL_USER2"), "password": os.getenv("EMAIL_PASS2")},
    {"email": os.getenv("EMAIL_USER3"), "password": os.getenv("EMAIL_PASS3")},
]

def check_new_emails(account):
    email_user = account["email"]
    email_pass = account["password"]

    mail = imaplib.IMAP4_SSL(imap_server)

    try:
        mail.login(email_user, email_pass)
        mail.select("inbox") 
        status, messages = mail.search(None, "UNSEEN")

        if status == "OK" and messages[0]:
            messages = messages[0].split()
            new_emails_count = len(messages)
            print(f"{email_user} has {new_emails_count} new emails.")
        else:
            print(f"{email_user} has no new emails.")

        mail.close()
        mail.logout()
    except Exception as e:
        print(f"Error with {email_user}: {e}")

for account in accounts:
    check_new_emails(account)

