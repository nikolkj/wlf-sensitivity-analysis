# ABOUT: Degradation Scenarios applicable to aircraft names only

# SAVE OUTPUT DEGRADATIONS ----
# only retain key output
saveRDS(object = deg, file = "run-files/degrdation-output_aircraft.rds")

# reset environment
rm(list = ls())
load("run-files/snapshot_prepared-data.Rdata")