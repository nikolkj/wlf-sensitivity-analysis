# ABOUT ----
# Pull OFAC CONS files (CSV) and parse.
# (1) Main listings
# (2) Address data
#   ... Enrich geographic data with ISO-codes, geographic region labeling, etc.
# Export to "datarepo/cons_files_parsed.RData".  

# Start-up ----
rm(list = ls()); invisible(gc());
require(tidyverse)
require(magrittr)
require(httr)

# Header Definitions ----
# Per Treasury Technical Documentation
# ... See "https://home.treasury.gov/system/files/126/data_specification.txt". 

# SDN Listing Header 
header.cons = c("ent_num", "SDN_Name", "SDN_Type", "Program", "Title", 
               "Call_Sign", "Vess_type", "Tonnage", "GRT", "Vess_flag",
               "Vess_owner", "Remarks") # Per tech-specs
header.cons = toupper(header.cons)

# SDN Supplementary Address Data Header 
header.cons_add = c("ent_num", "add_num", "Address", "City_State_Postal", 
               "Country", "Remarks") # Per tech-specs
header.cons_add = toupper(header.cons_add)

# SDN Alternate Name Data Header 
header.cons_alt = c("ent_num", "alt_num", "alt_type", "alt_name", 
               "alt_remarks") # Per tech-specs
header.cons_alt = toupper(header.cons_alt)

# Pull & Process OFAC SDN File ----
# Pull CSV Data-File 
cons.prim = suppressWarnings(RCurl::getURL("https://www.treasury.gov/ofac/downloads/consolidated/cons_prim.csv",
                                         ssl.verifyhost=FALSE, ssl.verifypeer=FALSE) %>%
                             read_csv(file = ., col_names = header.cons,
                                      quote = "\"", na = "-0-", col_types = cols(.default = "c"),
                                      trim_ws = TRUE, progress = TRUE)
)

# Pre-processing
# > Simple fixes ...
suppressWarnings({cons.prim$ENT_NUM %<>% as.integer()}) # Convert entry UID to interger
cons.prim = cons.prim %>% 
  filter(!is.na(ENT_NUM)) %>% # Drop bad entry (trailing empty record)
  mutate(SDN_TYPE = ifelse(test = is.na(SDN_TYPE), "entity", SDN_TYPE), # business entities are coded as blanks (NA) in raw data, fix
         SDN_TYPE = factor(SDN_TYPE)
  ) 

# > Fix [PROGRAM] field
# ... Native field encodes one-to-many relationships
# ... Also, fairly inconsistent "[]" char separation 
program_mappings = cons.prim$PROGRAM

# Clean-up delimiting for parsing
leftpad = !grepl(pattern = "^\\[", x = program_mappings) # # identify which need left-padding
program_mappings[leftpad] = paste0("[", program_mappings[leftpad]) # apply
rightpad = !grepl(pattern = "\\[$", x = program_mappings) # identify which need right-padding
program_mappings[rightpad] = paste0(program_mappings[rightpad], "]") # apply

rm(leftpad, rightpad)

# Parse into list 
program_mappings = lapply(X = program_mappings, 
                          FUN = function(x){str_split(string = x, pattern = "\\s*\\[") %>% 
                              unlist() %>% .[-1] %>%
                              gsub(pattern = "\\]$", replacement = "", x = .)
                          }
)

# Attach Parsed list obj back to oringal df
# ... Allows to see which programs are associated with each entry
cons.prim$PROGRAM = vector(mode = "list", length = nrow(cons.prim))
cons.prim$PROGRAM = program_mappings

# Create Catalog 
# ... Allows reverse-search from specific program to all associated [ENT_NUM] values
program_catalog.cons = tibble(PROGRAM = unique(unlist(program_mappings)))
program_catalog.cons$ENT_NUMS = vector(mode = "list", length = nrow(program_catalog.cons))
for(i in seq_along(program_catalog.cons$PROGRAM)){
  program_catalog.cons$ENT_NUMS[[i]] = sapply(cons.prim$PROGRAM, function(xl) {
    program_catalog.cons$PROGRAM[i] %in% xl
  }) %>% which() %>% cons.prim$ENT_NUM[.] 
  
}

# Clean-up
rm(program_mappings, i)


# Pull & Process OFAC ADD File ----
# ... Contains (address) details for SDN entries, where available
# ... Downstream processing applies regional encodings

# Pull CSV Data-File 
cons.add = suppressWarnings(RCurl::getURL("https://www.treasury.gov/ofac/downloads/consolidated/cons_add.csv",
                                         ssl.verifyhost=FALSE, ssl.verifypeer=FALSE) %>%
                             read_csv(file = ., col_names = header.cons_add,
                                      quote = "\"", na = "-0-", col_types = cols(.default = "c"),
                                      trim_ws = TRUE, progress = TRUE)
)

# > Simple Fixes 
cons.add = cons.add %>% 
  mutate(ENT_NUM = suppressWarnings({as.integer(ENT_NUM)}),
         ADD_NUM = suppressWarnings({as.integer(ADD_NUM)})) %>% 
  filter(!is.na(ENT_NUM) & !is.na(ADD_NUM)) %>% 
  mutate(COUNTRY = factor(COUNTRY))


# > Region-Encoding
# Get country codes from github. ISO-3166 standard.
country_codes = RCurl::getURL("https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.csv") %>% 
  read_csv(file = ., col_names = TRUE, col_types = cols(.default = "c"), trim_ws = TRUE, na = "")

# Fix country-naming differences between the dfs
# ... based on manually compiled patch-file "~/country_name_fix.csv"
setdiff(levels(cons.add$COUNTRY), country_codes$name) # ptc mis-matches
country_codes$alt_name = country_codes$name
country_name_fix = read_csv("datarepo/reference-files/country_name_fix.csv", na = "", 
                            col_names = TRUE, trim_ws = TRUE, 
                            col_types = cols(.default = col_character())
)
country_codes$alt_name[country_codes$alt_name %in% country_name_fix$iso_name] = 
  country_name_fix$ofac_name[match(country_codes$alt_name[country_codes$alt_name %in% country_name_fix$iso_name], 
                                   country_name_fix$iso_name)]

country_codes %>% filter(is.na(alt_name)) # ptc, should return 0-row tibble; otherwise add entry to "country_name_fix.csv"


# Join ISO-table Info to SDN ADD df
cons.add = cons.add %>% 
  left_join(x = ., y = country_codes,
            by = c("COUNTRY" = "alt_name")) %>% 
  filter(!is.na(`alpha-2`)) # drop records that could not be enriched

# Clean-up
rm(country_codes, country_name_fix)

# Pull and Process OFAC CONS ALT File ----
cons.alt = suppressWarnings(RCurl::getURL("https://www.treasury.gov/ofac/downloads/consolidated/cons_alt.csv",
                                         ssl.verifyhost=FALSE, ssl.verifypeer=FALSE) %>%
                             read_csv(file = ., col_names = header.cons_alt,
                                      quote = "\"", na = "-0-", col_types = cols(.default = "c"),
                                      trim_ws = TRUE, progress = TRUE)
)

cons.alt = cons.alt %>% 
  filter(ALT_TYPE == "aka") %>% # drop weak aliases
  mutate(ENT_NUM = as.integer(ENT_NUM), # update field types
         ALT_NUM = as.integer(ALT_NUM)
  ) %>%
  select(-ALT_REMARKS) %>% 
  left_join(x = ., 
            y = (cons.prim %>% select(ENT_NUM, SDN_TYPE) %>% unique()),
            by = "ENT_NUM"
  )


# Export binary of output files ----
cons.timestamp = Sys.time() # timestamp when data was sourced

save(cons.timestamp, cons.prim, cons.add, cons.alt, program_catalog.cons, file = "datarepo/cons_files_parsed.RData", version = 3)
rm(list = ls()); invisible(gc())


