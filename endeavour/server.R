#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    # Params: Helpers ----
    shinyhelper::observe_helpers()
    
    
    # Read Scenario Configuration Files ----
    scenario_config.general = read_csv(
        file = "scenario-config_general.csv",
        col_names = TRUE,
        col_types = cols(.default = "c"),
        quote = "\"",
        trim_ws = TRUE
    ) %>%
        # make row-wise list
        filter(!is.na(scenario_id) & !is.na(scenario_label)) %>%
        split(., seq(nrow(.))) %>%
        lapply(., unlist)

    scenario_config.individuals = read_csv(
        file = "scenario-config_individuals.csv",
        col_names = TRUE,
        col_types = cols(.default = "c"),
        quote = "\"",
        trim_ws = TRUE
    ) %>%
        # make row-wise list
        filter(!is.na(scenario_id) & !is.na(scenario_label)) %>%
        split(., seq(nrow(.))) %>%
        lapply(., unlist)
    
    scenario_config.entities = read_csv(
        file = "scenario-config_entities.csv",
        col_names = TRUE,
        col_types = cols(.default = "c"),
        quote = "\"",
        trim_ws = TRUE
    ) %>%
        # make row-wise list
        filter(!is.na(scenario_id) & !is.na(scenario_label)) %>%
        split(., seq(nrow(.))) %>%
        lapply(., unlist)
    
    
    # Create Scenario Selection Switches ----
    # ... based on [scenario_config.*] vars, above
    
    output$scenario_select_general = renderUI({

        lapply(scenario_config.general, function(x) {
            prettySwitch(
                inputId = x[[1]],
                label = x[[2]],
                value = TRUE,
                status = "primary",
                fill = TRUE
            )
        })
    })
    
    output$scenario_select_individuals = renderUI({

        lapply(scenario_config.individuals, function(x) {
            prettySwitch(
                inputId = x[[1]],
                label = x[[2]],
                value = TRUE,
                status = "primary",
                fill = TRUE
            )
        })
    })

    output$scenario_select_entities = renderUI({

        lapply(scenario_config.entities, function(x) {
            prettySwitch(
                inputId = x[[1]],
                label = x[[2]],
                value = TRUE,
                status = "primary",
                fill = TRUE
            )
        })
    })
    
    

})
