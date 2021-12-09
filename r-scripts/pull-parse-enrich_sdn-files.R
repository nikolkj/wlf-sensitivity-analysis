# ABOUT ----
# Pull OFAC SDN files (CSV) and parse.
# (1) Main listings
# (2) Address data
#   ... Enrich geographic data with ISO-codes, geographic region labeling, etc.
# Export to "datarepo/sdn_files_parsed.RData".  

# Start-up ----
rm(list = ls()); invisible(gc());
suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
require(magrittr)
require(httr)
require(assertthat)

# Header Definitions ----
# Per Treasury Technical Documentation
# ... See "https://home.treasury.gov/system/files/126/data_specification.txt". 

# SDN Listing Header 
header.sdn = c("ent_num", "SDN_Name", "SDN_Type", "Program", "Title", 
               "Call_Sign", "Vess_type", "Tonnage", "GRT", "Vess_flag",
               "Vess_owner", "Remarks") # Per tech-specs
header.sdn = toupper(header.sdn)

# SDN Supplementary Address Data Header 
header.add = c("ent_num", "add_num", "Address", "City_State_Postal", 
               "Country", "Remarks") # Per tech-specs
header.add = toupper(header.add)

# SDN Alternate Name Data Header 
header.alt = c("ent_num", "alt_num", "alt_type", "alt_name", 
              "alt_remarks") # Per tech-specs
header.alt = toupper(header.alt)

# Pull & Process OFAC SDN File ----
# Pull CSV Data-File 
# TODO add tryCatch read using httr
sdn.prim = suppressWarnings(tryCatch(expr = "https://www.treasury.gov/ofac/downloads/sdn.csv",
                                         ssl.verifyhost=FALSE, ssl.verifypeer=FALSE) %>%
                             read_csv(file = ., col_names = header.sdn,
                                      quote = "\"", na = "-0-", col_types = cols(.default = "c"),
                                      trim_ws = TRUE, progress = TRUE)
                           )

# Pre-processing
# > Simple fixes ...
suppressWarnings({sdn.prim$ENT_NUM %<>% as.integer()}) # Convert entry UID to integer
sdn.prim = sdn.prim %>% 
  filter(!is.na(ENT_NUM)) %>% # Drop bad entry (trailing empty record)
  mutate(SDN_TYPE = ifelse(test = is.na(SDN_TYPE), "entity", SDN_TYPE), # business entities are coded as blanks (NA) in raw data, fix
         SDN_TYPE = factor(SDN_TYPE)
         ) 

# > Fix [PROGRAM] field
# ... Native field encodes one-to-many relationships
# ... Also, fairly inconsistent "[]" char separation 
program_mappings = sdn.prim$PROGRAM

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

# Attach Parsed list obj back to original df
# ... Allows to see which programs are associated with each entry
assertthat::assert_that(are_equal(nrow(sdn.prim), length(program_mappings)), msg = '"program_mappings" length must equal nrow of "sdn.prim"')
sdn.prim$PROGRAM = vector(mode = "list", length = nrow(sdn.prim))
sdn.prim$PROGRAM = program_mappings

# Create Catalog 
# ... Allows reverse-search from specific program to all associated [ENT_NUM] values
program_catalog = tibble(PROGRAM = unique(unlist(program_mappings)))
program_catalog$ENT_NUMS = vector(mode = "list", length = nrow(program_catalog))
for(i in seq_along(program_catalog$PROGRAM)){
  program_catalog$ENT_NUMS[[i]] = sapply(sdn.prim$PROGRAM, function(xl) {
    program_catalog$PROGRAM[i] %in% xl
  }) %>% which() %>% sdn.prim$ENT_NUM[.] 
  
}

program_catalog.sdn = program_catalog # rename var b/c cons file also has a catalog

# Clean-up
rm(program_catalog, program_mappings, i)


# Pull & Process OFAC ADD File ----
# ... Contains (address) details for SDN entries, where available
# ... Downstream processing applies regional encodings

# Pull CSV Data-File 
# TODO add tryCatch read using httr
sdn.add = suppressWarnings(RCurl::getURL("https://www.treasury.gov/ofac/downloads/add.csv",
                                         ssl.verifyhost=FALSE, ssl.verifypeer=FALSE) %>%
                             read_csv(file = ., col_names = header.add,
                                      quote = "\"", na = "-0-", col_types = cols(.default = "c"),
                                      trim_ws = TRUE, progress = TRUE)
                           )

# > Simple Fixes 
sdn.add = sdn.add %>% 
  mutate(ENT_NUM = suppressWarnings({as.integer(ENT_NUM)}),
         ADD_NUM = suppressWarnings({as.integer(ADD_NUM)})) %>% 
  filter(!is.na(ENT_NUM) & !is.na(ADD_NUM)) %>% 
  mutate(COUNTRY = factor(COUNTRY))


# > Region-Encoding
# Get country codes from github. ISO-3166 standard.
country_codes.path = "https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.csv"
country_codes = tryCatch(expr = {RCurl::getURL(country_codes.path)}, 
                         error = function(e){httr::GET(url = country_codes.path) %>% 
                             httr::content()}
                         ) %>% 
  read_csv(file = ., col_names = TRUE, col_types = cols(.default = "c"), trim_ws = TRUE, na = "") %>% 
  janitor::clean_names()

# Fix country-naming differences between the dfs
# ... based on manually compiled patch-file "~/country_name_fix.csv"
setdiff(levels(sdn.add$COUNTRY), country_codes$name) # TOCONSOLE: mis-matches
country_codes$alt_name = country_codes$name
country_name_fix = read_csv("ref-files/country_name_fix.csv", na = "", 
                            col_names = TRUE, trim_ws = TRUE, 
                            col_types = cols(.default = col_character())
                            )
  # TODO check to ensure there are no new mis-matches; patch reference file if necessary.
country_codes$alt_name[country_codes$alt_name %in% country_name_fix$iso_name] = 
  country_name_fix$ofac_name[match(country_codes$alt_name[country_codes$alt_name %in% country_name_fix$iso_name], 
                                   country_name_fix$iso_name)]

# Join ISO-table Info to SDN ADD df
sdn.add = sdn.add %>% 
  left_join(x = ., y = country_codes,
            by = c("COUNTRY" = "alt_name")) %>% 
  filter(!is.na(alpha_2)) # drop records that could not be enriched

# Clean-up
rm(country_codes, country_name_fix)

# Pull and Process OFAC ALT File ----
# TODO add tryCatch read using httr
sdn.alt = suppressWarnings(RCurl::getURL("https://www.treasury.gov/ofac/downloads/alt.csv",
                                         ssl.verifyhost=FALSE, ssl.verifypeer=FALSE) %>%
                             read_csv(file = ., col_names = header.alt,
                                      quote = "\"", na = "-0-", col_types = cols(.default = "c"),
                                      trim_ws = TRUE, progress = TRUE)
)

sdn.alt = sdn.alt %>% 
  filter(ALT_TYPE == "aka") %>% # drop weak aliases
  mutate(ENT_NUM = as.integer(ENT_NUM), # update field types
         ALT_NUM = as.integer(ALT_NUM)
         ) %>%
  select(-ALT_REMARKS) %>% 
  left_join(x = ., 
            y = (sdn.prim %>% select(ENT_NUM, SDN_TYPE) %>% unique()),
            by = "ENT_NUM"
            )


# Export binary of output files ----
sdn.timestamp = Sys.time() # timestamp when data was sourced

if(!dir.exists(paths = "run-files/")){
  # check if landing dir exists
  # ... if not, then create directory
  dir.create(path = "run-files")
}

save(sdn.timestamp, sdn.prim, sdn.add, sdn.alt, program_catalog.sdn, file = "run-files/sdn_files_parsed.RData", version = 3)
closeAllConnections()
rm(list = ls()); invisible(gc())


