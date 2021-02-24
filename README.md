# FitoTrack-logger
### What is this
FitoTrack-logger is a backend solution for storing on a database of yours what the [FitoTrack](https://codeberg.org/jannis/FitoTrack) app collects. Its purpose is to make the FitoTrack data query-able thanks to PostgreSQL and PostGIS.

If you don't know what the FitoTrack app is, here is the [README](https://codeberg.org/jannis/FitoTrack/src/branch/master/README.md)'s abstract:
```
FitoTrack is a mobile app for logging and viewing your workouts. Whether you're running, cycling or hiking, FitoTrack will show you the most important information, with detailed charts and statistics. It is open-source and completely ad-free.
```

Give the app a try:
<p align="center">
  <a href="https://play.google.com/store/apps/details?id=de.tadris.fitness"><img alt="Get it on Google Play" src="https://codeberg.org/jannis/FitoTrack/raw/branch/master/doc/badge-google-play.png" height="75"/></a>
  <a href="https://f-droid.org/packages/de.tadris.fitness"><img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="75"></a>
</p>

### Requirements for FitoTrack-logger
- a PostgreSQL database with the PostGIS extension enabled
- a mail address you have access to with username and password (gmail works but you have to enable the *app password* thing as OAuth isn't directly supported by this script)

### Disclaimer
This project is not affiliated with the FitoTrack developers.

Currently this script collects all the mails you have stored, downloads the attachments and deletes the messages from the server.
I'm personally using this script with a purpose-built fitotrack mail address.

If you don't have an easy way to create new mail addresses (like owning your personal mail server) you need to be careful when using this as it will delete all the messages you have from the mail account you point it to.

In order for it to have a more "graceful" functionality and play nice with other emails you might have in the inbox, you need to fiddle around with the IMAP filters defined in the `fitotrack_msg_filter` variable in the `main.py` file.

### How it works
You need a PostgreSQL database. Make sure to enable the famous PostGIS extension. [Here is the extension website](http://postgis.net) and the documentation on how to do that.

Once inside the project's directory, create a configuration file called `config.ini`.
This is a template with the required sections and fileds it needs (adjust as required):
```
[mail]
host=MAIL-HOST
username=MAIL-USERNAME
password=MAIL-PASSWORD

[db]
host=DATABASE-HOST
username=DATABASE-USERNAME
password=DATABASE-PASSWORD
database=DATABASE-NAME
```

In order to export the workout data from the app:
- open FitoTrack, tap on a completed activity from the main app view
- at the top right, tap the 3-dots menu icon
- select `Export as GPX-File`
- in the next dialog, tap `Share`
- share it with your phone's mail client. It will be sent as an attachment


Execute
```
python main.py
```

The script will:
- login into your mail account
- download all the mails it has and delete them from the server
- create a file in the newly created `gpx_files` folder
- parse them as GPX files with the `gpxpy` library ([link](https://github.com/tkrajina/gpxpy)) and load them in the PostgreSQL instance you configured. It works.

### Considerations
The project can be used from different people at the same time. It will distinguish the users by their mail address.

E.g. if you have a family or people you care about that are using FitoTrack to record their workout, you can collect the GPX data with this project. FitoTrack-logger is able to tag different users if the GPX files come from different mail addresses.
You could use the intersection queries of PostGIS to see whether you cross your paths with each other, where and when. It's fun.

### Performance considerations (expert eyes only)
I save the latitude and longitude points as a `GEOGRAPHY(POINT)` in the `geog` column of the `training_data` table. I'm aware of the performance implications of it. I just don't want to bother with the Cartesian projection required if I'd store them as a `GEOMETRY` point. Plus, as of now I'm not really doing anything with those points except storing them in the database.