from sqlalchemy.engine import Connection
from tabulate import tabulate

def print_stats(db: Connection):
    overall_stats = """
        select distinct
		        td.t::date,
		        date_trunc('second', training_duration.start_time::time) as start_time,
		        date_trunc('second', training_duration.end_time::time) as end_time,
                training_duration.duration as duration,
		        round(((t.moving_distance)/1000)::numeric, 2) as distance,
		        round(( (t.moving_distance / 1000) / (select extract(epoch from training_duration.duration)/3600))::numeric, 1) as pace_kmh
	        from training t
		        join training_data td on (t.id = td.training_id)
		        join training_duration on (t.id = training_duration.id)
        order by td.t::date, date_trunc('second', training_duration.start_time::time) asc
    """

    print(tabulate(list(db.execute(overall_stats)),
            headers = ["date", "start_time", "end_time", "duration", "distance", "pace (km/h)"]))