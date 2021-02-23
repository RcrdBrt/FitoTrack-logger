import configparser
from imaplib import IMAP4

from sqlalchemy import create_engine


config = configparser.ConfigParser().read('config.ini')
db = create_engine(f"postgresql://{config['db']['username']}:{config['db']['password']}@{config['db']['host']}/{config['db']['database']}")
mail = IMAP4(host=config['mail']['host'])


def get_gpx_files_from_mail():
    mail.login(config['mail']['username'], config['mail']['password'])

    mail.logout()


def main():
    pass


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        pass