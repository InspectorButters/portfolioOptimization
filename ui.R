library(shiny)
library(plotly)

shinyUI(fluidPage(
  
  #titlePanel("Portfolio Optimization"),
  
    tabsetPanel(
      tabPanel("Efficient Frontier", plotOutput("graphEF")),
      tabPanel("Transition Map", plotlyOutput("graphTM"))
      #tabPanel("Transition Map", plotOutput("graphTM"))
    ),
    
    wellPanel( 
        fluidRow(
          column(2,
                 sliderInput('ER_USLarge', h6("US Large Cap"), 0, min=0, max=30, step = 0.25),
                 sliderInput("ER_USMidCap", h6("US Mid Cap"), 0, min=0, max=30, step = 0.25)
                 ),
          column(2,
                 sliderInput("ER_USSmall", h6("US Small Cap"), 0, min=0, max=30, step = 0.25),
                 sliderInput("ER_IntlEurope", h6("Developed Europe"), 0, min=0, max=30, step = 0.25)
                 ),
          column(2,
                 sliderInput("ER_Pacific", h6("Developed Pacific"), 0, min=0, max=30, step = 0.25),
                 sliderInput("ER_IntlNorAm", h6("Greater Canada"), 0, min=0, max=30, step = 0.25)
                 ),
          column(2,
                 sliderInput("ER_IntlEmerging", h6("Emerging Mkts"), 0, min=0, max=30, step = 0.25),
                 sliderInput("ER_FixedTrsy", h6("US Treasuries"), 0, min=0, max=30, step = 0.25)
                 ),
          column(2,
                 sliderInput("ER_FixedCorporate", h6("Corporate Bonds"), 0, min=0, max=30, step = 0.25),
                 sliderInput("ER_FixedSectized", h6("Asset-Backed Issues"), 0, min=0, max=30, step = 0.25)
                 ),
          column(2,
                 numericInput('min_allocPCT', h6("Min Asset Class Weight%, 0% to 5%"),
                        0, min = 0, max = 5, step = 1),
                 br(),
                 actionButton("goButton","Generate", style="width:100%")
                 )
          ),
        style="padding:5px"
        )
    )
  )

