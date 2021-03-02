from sqlalchemy.engine import Connection
from tabulate import tabulate

def print_stats(db: Connection):
    overall_stats = """
        select *
            from training_info
    """

    print(tabulate(list(db.execute(overall_stats)),
            headers = ["date", "start_time", "end_time", "duration", "distance", "pace (km/h)"]))