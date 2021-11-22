# ABOUT: Degradation Scenarios applicable to individual names only

# Deg: Replace with Similar Names ----
# TODO ^
# ... e.g. Nikolai to Nicholas
# .... replacement list can be developed by scraping 'https://www.behindthename.com/'
# .... e.g. https://www.behindthename.com/name/nikolai
# ..... see 'Other Languages & Cultures' section





# SAVE OUTPUT DEGRADATIONS ----
# only retain key output
saveRDS(object = deg, file = "run-files/degrdation-output_individuals.rds")

# reset environment
rm(list = ls())
load("run-files/snapshot_prepared-data.Rdata")