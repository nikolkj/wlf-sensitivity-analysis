README: wlf-sensitivity-analysis
================
Nikolai Priser
11/15/2021

## Summary

High-level summary.

## Overview

### Project Directories

-   ‘**proj/r-scripts/**’: executable scripts for the project; write
    transient output to ‘proj/run-files/’.

-   ‘**proj/ref-files/**’: reference files that must be manually
    maintained unless explicitly specified.

-   ‘**proj/run-files/**’: landing location for transient output during
    script execution.

### Execution Order

All scripts are located in ‘**proj/run-files/**’ and are run through
production-mode, unless explicitly noted. Non-production files are run
*only* if **param.demo\_mode = TRUE**.

All scripts are called and executed in sequence by
**’proj/run-files/*main.R’****.* Scripts inherent global variables; see
in-line comments for global variables, inherited from *’*\_main.R’ or
predecessor scripts, for each script.

‘\_main.R’ sets execution parameters, see **Parameter Definitions**
section for additional details.

1.  **pull-parse-enrich\_sdn-files.R** Pulls OFAC SDN data, enriches
    geographic data and writes output to ‘proj/run-files/’

2.  **pull-parse-enrich\_cons-files.R** Pulls OFAC CONS data, enriches
    geographic data and writes output to ‘proj/run-files/’

3.  **degrade\_basics.R**  
    Executes degradation scenarios applicable for all types of names, as
    defined in \[raw\].\[SDN\_TYPE\] field.

4.  **degrade\_entities.R  
    **Executes degradation scenarios for only “entity” (e.g. businesses,
    organizations) type names, as defined in \[raw\].\[SDN\_TYPE\]
    field. See **Degradation Scenarios** section, below.

5.  **degrade\_individuals.R**  
    Executes degradation scenarios for only “individual” type names, as
    defined in \[raw\].\[SDN\_TYPE\] field. See **Degradation
    Scenarios** section, below.

6.  **degrade\_vessels.R**  
    Executes degradation scenarios for only “vessel” type names, as
    defined in \[raw\].\[SDN\_TYPE\] field. See **Degradation
    Scenarios** section, below.

7.  **degrade\_aircraft.R**  
    Executes degradation scenarios for only “aircraft” type names, as
    defined in \[raw\].\[SDN\_TYPE\] field. See **Degradation
    Scenarios** section, below.

8.  **demo\_match-names.R** \[demo script\]  
    Demo script to emulate a client watchlist screening model. Loads
    screening algorithms from
    ‘**r-scripts/testing\_comparsion\_algos.R**’ - all algorithm
    functions should follow the following naming syntax:
    “comparison\_algo\_\#\#” ensure that local functions are cleared
    following screening execution.

    Compares
    deg*t**e**s**t*<sub>*n*</sub>*a**m**e**v**a**l**u**e**s**a**g**a**i**n**s**t**w**a**t**c**h**l**i**s**t**w**l*<sub>*d*</sub>*a**t**a*prepd\_name
    values. Watchlist raw \[SDN\_NAME\] values are ignored because
    proper comparison requires name-format matching between the two sets
    of names; accounting for user-defined degradation parameters such as
    first-middle-last individual name formatting and dropping of
    middle-name details.

    -   Output Global Variables:

        -   model\_output: Dataframe of matching watchlist names;
            relates to \[\[deg\]\] tbl via common \[deg\_index\] field.
            Many-to-one relationship between deg$deg\_index and
            model\_output matches.

9.  **file-name.R** \[demo script\]  
    Script description.

10. **file-name.R** \[demo script\]  
    Script description.

11. **file-name.R** \[demo script\]  
    Script description.

### Parameter Definitions

**\*\*TODO\*\*** Parameters currently reside in ‘\_main.R’; once
finalized, parameters should be relocated to the project’s R Environment
File.

-   **parameter\_value  
    **Parameter Description

-   **parameter\_value  
    **Parameter Description

-   **parameter\_value  
    **Parameter Description

-   **parameter\_value  
    **Parameter Description

-   **parameter\_value  
    **Parameter Description

### Reference Files

-   **File Name.ext  
    **File Description

-   **File Name.ext  
    **File Description

-   **File Name.ext  
    **File Description

-   **File Name.ext  
    **File Description

### Degradation Scenarios

All scripts write output to named-list of dataframes called “deg”, which
is preallocated with zero-length in ‘\_main.R’; Each scenario gets a
dedicated code-block and follows the following structure:

1.  Copy prepared watchlist data to \[\[dat\]\], apply \[SDN\_TYPE\]
    filtering if necessary.  
    E.g. “*dat = raw; dat = dat %&gt;% filter(SDN\_TYPE = ‘type’)*”  
2.  Application degradation degraded logic on \[prepd\_name\] to
    generate \[test\_name\]
3.  Comparison between \[prepd\_name\] and \[test\_name\] to remove any
    un-altered \[test\_name\] values.
4.  Calculation of degradation benchmark metrics (e.g. levenshtein
    string distance) between \[prepd\_name\] and \[test\_name\] values
    using degDistance() function; defined in ‘**helper-funcs.R**’, see
    **Helper Function** section for more details.
5.  Sampling of observations based on user-defined parameters via
    ‘*code*’; trims outliers and samples based on reduced
    \[\[dat\]\].\[dist\_\*\] metrics. using
    sample\_degradations\_simple() function; defined in
    ‘**helper-funcs.R**’, see **Helper Function** section for more
    details.
6.  Appending of the sampled dataframe to ‘deg’ via “*deg = c(deg,
    "scenario-name" = list(dat))*”; each list element *must* be named
    with the corresponding scenario name to comply with bind\_rows()
    requirements in ‘\_main.R’.

-   **Basics Degradations:** ‘degrade\_basics.R’  
    Degradations applicable for all types of names, as defined in
    \[raw\].\[SDN\_TYPE\] field.

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

-   **Entity Degradations:** ’ degrade\_entities.R’  
    Degradations applicable for only “entity” (e.g. businesses,
    organizations) type names, as defined in \[raw\].\[SDN\_TYPE\]
    field.

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

    -   **Scenario Name  
        **Scenario Description

-   **Individual Degradations:** file-name.R  
    Degradations applicable for only “individual” type names, as defined
    in \[raw\].\[SDN\_TYPE\] field.

    -   **Scenario Name: NONE  
        \*\*TODO\*\*** No scenarios developed.

-   **Vessels Degradations:** file-name.R  
    Degradations applicable for only “vessel” type names, as defined in
    \[raw\].\[SDN\_TYPE\] field.

    -   **Scenario Name: NONE  
        \*\*TODO\*\*** No scenarios developed.

-   **Aircrafts Degradations:** file-name.R  
    Degradations applicable for only “aircraft” type names, as defined
    in \[raw\].\[SDN\_TYPE\] field.

    -   **Scenario Name: NONE  
        \*\*TODO\*\*** No scenarios developed.

### Helper Functions

Global environment functions defined in ‘script/path/’. Utilized
throughout the execution pipeline.

-   **splitName()**

-   **prettyName()**

-   **gramify()**

-   **degDistance()**

-   **sample\_degradations\_simple()**
