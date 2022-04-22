#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
rm(list = ls())
require(shiny)
require(tidyverse)
require(shinyWidgets)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel(title = "", 
               windowTitle = "Endeavour"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            navbarPage(
                title = "Options",
                tabPanel(title = "Scenario Selection",
                         
                         # tags$hr(),
                         HTML("<b>General Degradations</b><br><br>"),
                         # tags$h5("General Degradation"),
                         uiOutput(outputId = "scenario_select_general"),
                         
                         tags$hr(),
                         HTML("<b>Individual Degradations</b><br><br>"),
                         # tags$h5("Individual Degradations"),
                         uiOutput(outputId = "scenario_select_individuals"),

                         tags$hr(),
                         HTML("<b>Business Degradations</b><br><br>"),
                         # tags$h5("Business Degradations"), 
                         uiOutput(outputId = "scenario_select_entities")
                         ),
                
                
                tabPanel(title = "Name Formats",
                         
                         # tags$hr(),
                         HTML("<b>General Parameters</b><br><br>"),
                         pickerInput(inputId = "opts-name-types", 
                                     label = "Name Types", 
                                     choices = c("Primary Names", "AKAs"), 
                                     selected = "Primary Names",
                                     multiple = TRUE,
                                     width = "75%"
                         ) %>%
                             shinyhelper::helper(shiny_tag = ., 
                                                 icon = "question-circle", 
                                                 colour = "#0d6efd", # "#0dcaf0", # boot-strap primar/info
                                                 type = "inline", 
                                                 content = c("<h4>Information: Name Types</h4>",
                                                             "Generally, testing primary OFAC names is sufficient.",
                                                             "However, you can test AKAs, too, if you want."
                                                             ),
                                                 size = "m", buttonLabel = "OK"),
                         
                         tags$hr(),
                         HTML("<b>Individual Name Options</b><br><br>"),
                         prettySwitch(inputId = "opts-fml",
                                      label = "Format to First Middle Last",
                                      value = TRUE,
                                      status = "primary", 
                                      fill = TRUE
                                      ) %>% 
                             shinyhelper::helper(shiny_tag = ., 
                                                 icon = "question-circle", 
                                                 colour = "#0d6efd", # "#0dcaf0", # boot-strap primar/info
                                                 type = "inline", 
                                                 content = c("<h4>Information: Individual Name Formatting</h4>",
                                                             "By default OFAC individual names are in the \"<b>Last,</b> <i>First Middle</i>\" format."),
                                                 size = "m", buttonLabel = "OK"),
                         
                         prettySwitch(inputId = "opts-drop-middle",
                                      label = "Drop Middle Names",
                                      status = "primary", 
                                      value = TRUE,
                                      fill = TRUE
                         ) %>%
                             shinyhelper::helper(shiny_tag = ., 
                                                 icon = "question-circle", 
                                                 colour = "#0d6efd", # "#0dcaf0", # boot-strap primar/info
                                                 type = "inline", 
                                                 content = c("<h4>Information: Middle Names</h4>",
                                                             "Should middle names be dropped? This is an additional stressor for models.",
                                                             "Some scenarios may perform worse that they would otherwise.",
                                                             "Ignored for by scenarios; see documentation."),
                                                 size = "m", buttonLabel = "OK"),
                         
                         tags$hr(),
                         HTML("<b>Specific Scenario Options</b><br><br>"),
                         numericInput(inputId = "opts-long-names", 
                                      label = "Long Names Cut-off Length", 
                                      value = 35, 
                                      min = 35, max = 500, 
                                      width = "75%") %>%
                             shinyhelper::helper(shiny_tag = ., 
                                                 icon = "question-circle", 
                                                 colour = "#0d6efd", # "#0dcaf0", # boot-strap primar/info
                                                 type = "inline", 
                                                 content = c("<h4>Information: Long Name Cut-off Length</h4>",
                                                             "Names are truncated at a specific length corresponding to Fedwire, SWIFT and IAT messages. The 35-character default correponds to standard Fedwire party name limit (e.g. {4200}); see documentation."
                                                             ),
                                                 size = "m", buttonLabel = "OK")
                         
                         
                         )
                
                
            )
        ),

        # Show a plot of the generated distribution
        mainPanel(
            tabsetPanel(
                tabPanel(title = "First Panel"),
                tabPanel(title = "Second Panel"),
                tabPanel(title = "Help")
                ))
    )
))
