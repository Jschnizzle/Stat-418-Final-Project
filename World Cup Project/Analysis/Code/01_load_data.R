


# Preliminaries
# ------------------------------------------------------------------------------------------------------------
rm( list = ls() )

if( !requireNamespace( "sqldf", quietly = TRUE ) ) install.packages( "sqldf" )

library( sqldf )



# Data source
# ------------------------------------------------------------------------------------------------------------
# The dataset is the datahub.io relational World Cup package ( 38 tables ), published at
# https://datahub.io/football/worldcup . Each table has a stable r-link URL; the full list lives in the
# top-level footballworldcup.txt. This script ( re )downloads any missing CSVs into ../Data, then reads the
# core tables and prints a quick sqldf sanity summary. Data is persisted so later scripts don't re-download.
Prefix <- '../Data/'

Base_URL <- 'https://datahub.io/football/worldcup/_r/-/'

Resources <- c( "attendance-by-edition.csv", "attendance.csv", "award_winners.csv", "awards.csv",
                "bookings.csv", "confederations.csv", "datapackage.json",
                "dirtiest-matches-summary.csv", "discipline-by-tournament-summary.csv",
                "goal-timing-by-tournament-summary.csv", "goals-by-minute-summary.csv", "goals.csv",
                "group_standings.csv", "groups.csv", "host_countries.csv", "manager_appearances.csv",
                "manager_appointments.csv", "managers.csv", "matches.csv", "penalty_kicks.csv",
                "player_appearances.csv", "players.csv", "qualified_teams.csv", "referee_appearances.csv",
                "referee_appointments.csv", "referees.csv", "squads.csv", "stadiums.csv",
                "substitutions.csv", "team_appearances.csv", "teams.csv", "top-scorers-summary.csv",
                "tournament-appearances.csv", "tournament-goals-summary.csv", "tournament_stages.csv",
                "tournament_standings.csv", "tournaments.csv" )



# Download any missing files
# ------------------------------------------------------------------------------------------------------------
# Only fetches what isn't already on disk, so re-running is cheap. Comment out this block to work purely
# from the local copy already saved in ../Data.
if( !dir.exists( Prefix ) ) dir.create( Prefix, recursive = TRUE )

for( File in Resources )
{
  Destination <- paste0( Prefix, File )

  if( !file.exists( Destination ) )
  {
    cat( "Downloading ", File, "\n", sep = "" )

    try( download.file( paste0( Base_URL, File ), Destination, mode = "wb", quiet = TRUE ) )
  }
}



# Load core tables
# ------------------------------------------------------------------------------------------------------------
# A helper that reads a CSV from the Data folder with sane defaults. The 38 tables join on shared keys
# ( tournament_id, team_id, player_id, match_id ); here we pull the handful the modeling work leans on.
Read_Table <- function( File ) read.csv( paste0( Prefix, File ), stringsAsFactors = FALSE )

Tournaments     <- Read_Table( "tournaments.csv" )
Teams           <- Read_Table( "teams.csv" )
Group_Standings <- Read_Table( "group_standings.csv" )
Matches         <- Read_Table( "matches.csv" )
Squads          <- Read_Table( "squads.csv" )
Players         <- Read_Table( "players.csv" )
Bookings        <- Read_Table( "bookings.csv" )

World_Cup <- list( Tournaments     = Tournaments,
                   Teams           = Teams,
                   Group_Standings = Group_Standings,
                   Matches         = Matches,
                   Squads          = Squads,
                   Players         = Players,
                   Bookings        = Bookings )



# Quick look
# ------------------------------------------------------------------------------------------------------------
cat( "\nTables loaded:", length( World_Cup ), "\n" )

cat( "Row counts by table:\n" )

print( sapply( World_Cup, nrow ) )

cat( "\nTournaments by year and gender ( from group_standings ):\n" )

Tournament_Counts <- sqldf( "SELECT   tournament_name,
                                      SUM( CASE WHEN tournament_name LIKE '%Men''s%' THEN 1 ELSE 0 END ) AS Mens_Rows,
                                      COUNT(*) AS N
                            FROM     Group_Standings
                            GROUP BY tournament_name
                            ORDER BY tournament_name" )

print( Tournament_Counts )



# Save
# ------------------------------------------------------------------------------------------------------------
# Persist the core tables as a single .rds so later scripts ( EDA, joins, models ) can load fast without
# re-reading seven CSVs. Saved in the Data folder alongside the raw CSVs.
saveRDS( World_Cup, paste0( Prefix, 'world_cup_core.rds' ) )

cat( "\nSaved core tables to:", normalizePath( paste0( Prefix, 'world_cup_core.rds' ), mustWork = FALSE ), "\n" )
