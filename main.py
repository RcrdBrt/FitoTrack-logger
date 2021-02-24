import configparser
from imaplib import IMAP4
import ssl
import email
import os
from glob import glob
import sys
from gpxpy import gpx

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection
import gpxpy


config = configparser.ConfigParser()
config.read('config.ini')

db = create_engine(f"postgresql://{config['db']['username']}:{config['db']['password']}@{config['db']['host']}/{config['db']['database']}").connect()

mail = IMAP4(host=config['mail']['host'])
fitotrack_msg_filter = '(OR SUBJECT "fitotrack" SUBJECT "Fitotrack" SUBJECT "FITOTRACK" SUBJECT "FitoTrack")'


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
    _, ids = mail.search(None, fitotrack_msg_filter)
    ids = ids[0].split()
    for i in ids:
        _, fetched = mail.fetch(i, '(RFC822)')
        email_message = email.message_from_bytes(fetched[0][1])
        for part in email_message.walk():
            if part.get_content_maintype() == 'multipart' or part.get_content_disposition() is None:
                continue
            filename = part.get_filename()

            if filename and not os.path.exists(f'gpx_files/{filename}'):
                with open(os.path.join('gpx_files', filename), 'wb') as f:
                    f.write(part.get_payload(decode=True))
    
    mail.logout()


def process_gpx_files(tx: Connection, owner: str):
    for filepath in glob('gpx_files/*.gpx'):
        filename = os.path.split(filepath)[-1]
        if list(db.execute(text('select exists(select from training where filename = :filename)'), dict(filename=filename)))[0][0]:
            continue
        with open(filepath) as f:
            gpx_file = gpxpy.parse(f)
            if gpx_file.creator != 'FitoTrack':
                raise ValueError('gpx file not generated by the FitoTrack app')
            training_id = list(db.execute(
                'insert into training (owner, filename, medium, description) values (:owner, :filename, :medium, :description) returning id',
                (owner, filename, )
            ))[0][0]



def main(owner: str):
    init_database()
    get_gpx_files_from_mail()
    db.transaction(process_gpx_files, owner)


if __name__ == '__main__':
    try:
        main(sys.argv[1])
    except IndexError:
        print('Run the script with "python main.py OWNER_NAME"')
    except (KeyboardInterrupt, EOFError):
        pass
