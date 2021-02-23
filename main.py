import configparser
from imaplib import IMAP4

from sqlalchemy import create_engine


config = configparser.ConfigParser().read('config.ini')
db = create_engine(f"postgresql://{config['db']['username']}:{config['db']['password']}@{config['db']['host']}/{config['db']['database']}")


def main():
    pass


if __name__ == '__main__':
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        pass