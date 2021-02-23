import configparser
from imaplib import IMAP4

from sqlalchemy import create_engine


config = configparser.ConfigParser().read('config.ini')
db = create_engine(f"postgresql://{config['db'][1]}:{config['db'][2]}@{config['db'][0]}/{config['db'][3]}")
mail = IMAP4(host=config['mail'][0])



def init_database():
    with open('init.sql') as f:
        db.execute('\n'.join(f.readlines()))


def get_gpx_files_from_mail():
    mail.login(config['mail'][1], config['mail'][2])

    mail.logout()


def main():
    pass


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        pass