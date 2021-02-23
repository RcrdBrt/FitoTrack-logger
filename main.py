import configparser
from imaplib import IMAP4
import ssl

from sqlalchemy import create_engine


config = configparser.ConfigParser()
config.read('config.ini')

db = create_engine(f"postgresql://{config['db']['username']}:{config['db']['password']}@{config['db']['host']}/{config['db']['database']}").connect()

mail = IMAP4(host=config['mail']['host'])


def init_database():
    with open('init.sql') as f:
        db.execute('\n'.join(f.readlines()))


def get_gpx_files_from_mail():
    mail.starttls(ssl.create_default_context())
    mail.login(config['mail']['username'], config['mail']['password'])

    mail.logout()


def main():
    init_database()
    get_gpx_files_from_mail()


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        pass