import configparser
from imaplib import IMAP4
import ssl
import email
import os

from sqlalchemy import create_engine


config = configparser.ConfigParser()
config.read('config.ini')

db = create_engine(f"postgresql://{config['db']['username']}:{config['db']['password']}@{config['db']['host']}/{config['db']['database']}").connect()

mail = IMAP4(host=config['mail']['host'])
fitotrack_msg_filter = '(OR SUBJECT "fitotrack" SUBJECT "Fitotrack" SUBJECT "FITOTRACK")'


def init_database():
    with open('init.sql') as f:
        db.execute('\n'.join(f.readlines()))


def get_gpx_files_from_mail():
    try:
        os.mkdir('gpx_files')
    except FileExistsError:
        pass
    mail.starttls(ssl.create_default_context())
    mail.login(config['mail']['username'], config['mail']['password'])

    mail.create(config['mail']['mailbox_dir'])
    mail.select()
    (resp, ids) = mail.search(None, fitotrack_msg_filter)
    ids = ids[0].split()
    for i in ids:
        resp, fetched = mail.fetch(i, '(RFC822)')
        email_message = email.message_from_bytes(fetched[0][1])
        for part in email_message.walk():
            if part.get_content_maintype() == 'multipart' or part.get_content_disposition() is None:
                continue
            filename = part.get_filename()

            if filename:
                with open(os.path.join('gpx_files', filename), 'wb') as f:
                    f.write(part.get_payload(decode=True))
    
    mail.logout()


def main():
    init_database()
    get_gpx_files_from_mail()


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        pass
