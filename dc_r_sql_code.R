##
# ESR KSC Data Carpentry workshop - 26th June 2019
# R SQL lession code and notes notes
# link: https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html

# install required packages
install.packages(c("tidyverse", "RSQLite"))

# load packages
library(tidyverse)
library(dplyr)
library(dbplyr)

# create the data dir if needed
dir.create("data", showWarnings = FALSE)

# download the database
download.file(url = "https://ndownloader.figshare.com/files/2292171",
              destfile = "data/portal_mammals.sqlite", mode = "wb")

# make the database connection
mammals <- DBI::dbConnect(RSQLite::SQLite(), "data/portal_mammals.sqlite")

# check connection
src_dbi(mammals)

# we can form SQL queries 
tbl(mammals, sql("SELECT year, species_id, plot_id FROM surveys"))

# ...or we can use tidyverse structures
surveys <- tbl(mammals, "surveys")

# you don't need to learn SQL syntax
surveys %>%
  select(year, species_id, plot_id)

# look at the head of the retrieved data
head(surveys, n = 10)
# looks good

# now how about nrows?
nrow(surveys)
# hmmm, SQL doesn't return all the data 
# so R has no way of knowning the total number of rows 

# we can print out the actual SQL query
show_query(head(surveys, n = 10))

# lets do some more tidyverse 'stuff'!
surveys %>%
  filter(weight < 5) %>%
  select(species_id, sex, weight)

# we can also asign to an object as before
data_subset <- surveys %>%
  filter(weight < 5) %>%
  select(species_id, sex, weight)

# then work with that
data_subset %>%
  select(-sex)

# the above will only return the first 10 rows of data
# to get all rows we use collect()
data_subset <- surveys %>%
  filter(weight < 5) %>%
  select(species_id, sex, weight) %>%
  collect()

# check that
nrow(data_subset)

# let's grab another table from the database
plots <- tbl(mammals, "plots")

# look at it
plots

# and surveys
surveys

# now we can join the two tables together
plots %>%
  filter(plot_id == 1) %>%
  inner_join(surveys) %>%
  collect()

# grab the species table
species <- tbl(mammals, "species")

# do a join of surveys and species and create a cool table
left_join(surveys, species) %>%
  filter(taxa == "Rodent") %>%
  group_by(taxa, year) %>%
  tally %>%
  collect()

# same thing but grouping by genus
# estimating the number of individuals belonging to each genus found in each plot type
genus_counts <- left_join(surveys, plots) %>%
  left_join(species) %>%
  filter(taxa == "Rodent") %>%
  group_by(plot_type, genus) %>%
  tally %>%
  collect()

# print out to view
genus_counts

# unique genera
# number of genera found in each plot type
# n_distinct counts unique vaules in a column
unique_genera <- left_join(surveys, plots) %>%
  left_join(species) %>%
  group_by(plot_type) %>%
  summarize(
    n_genera = n_distinct(genus)
  ) %>%
  collect()

# print out to view
unique_genera


###
# Make your own database

# download data
download.file("https://ndownloader.figshare.com/files/3299483",
              "data/species.csv")
download.file("https://ndownloader.figshare.com/files/10717177",
              "data/surveys.csv")
download.file("https://ndownloader.figshare.com/files/3299474",
              "data/plots.csv")

# read in data files
species <- read_csv("data/species.csv")
surveys <- read_csv("data/surveys.csv")
plots <- read_csv("data/plots.csv")

# create directory if it doesn't exist
dir.create("data_output", showWarnings = FALSE)

# create database file
my_db_file <- "data_output/portal-database-output.sqlite"
my_db <- src_sqlite(my_db_file, create = TRUE)

# check it out
my_db

# add some data/tables to database
copy_to(my_db, surveys)
copy_to(my_db, plots)

# check it out
my_db

# copy the last table to the database
copy_to(my_db, species)

# check it our
my_db
