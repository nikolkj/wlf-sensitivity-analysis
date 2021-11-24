README: wlf-sensitivity-analysis
================
Nikolai Priser
11/15/2021

## Summary

Sets the foundation for sensitivity analysis; see downstream comments
regarding further development opportunities. Additionally, items
identified as “**TODO**” are pending development and are not currently
available.

Key Operations:

1.  Generate degradation samples by scenario for testing.

2.  **TODO**; Create Input file(s) for client system for screening.

3.  **TODO**; Parsing of client system output and adjudication of
    true-positive / false-positive results.

4.  Evaluation of Scenario performance as “sufficient” or “deficient”
    based on overall performances and client-performance expectations.

5.  **TODO**; Generation of Model Sensitivity Analysis markdown report
    summarizing scenario performance results and calibration opportunity
    results.

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

9.  **(… TODO …)**  
    Script(s) for integrating degradation samples with model output.
    Pending development - see code-block “Input/Output Data
    Integration”. Script(s) should be client system specific
    (e.g. Actimize, Prime, etc.).

10. **model\_sensitivity.R**  
    Evaluates model sensitivity by evaluating scenario true-positive
    match performance for each scenario. Scenarios where the
    true-positive match rate is above the corresponding parameter
    threshold are classified as “sufficient”. Similarly, scenarios where
    the true-positive match rate is below the corresponding parameter
    threshold are classified as “deficient”.

    Scenarios whose performance is between these thresholds are
    classified as “To Be Determined” and undergo further modeling.
    Modeling is conducted in through two-phases: (1) true-positive match
    boundary analysis and (2) modeling of client expectations.

    This approach is under the theory that if a decision-boundary model
    can be developed for model’s performance for a given scenario, that
    decision-boundary can then be evaluated to determine whether it
    generally aligns with management expectations. If the
    decision-boundary aligns with management expectations then the
    status of the scenario can be updated to “sufficient”; if it does
    not, it can be updated to “deficient”.

    Under the current methodology, distance-metrics calculated by the
    **degDistance()** helper function undergo PCA dimensional reduction
    to address predictor correlation issues and then are modeled using
    linear discriminant analysis. The use of LDA is purely judgemental
    and based on visualization of class-separation achieved through
    PC1 + PC2 plotting; see corresponding code-block titled
    “Visualizations of Scenario Performance”. LDA modeling under
    demo-mode conditions produced high AUC models with accuracy
    rates &gt; 90% on test data with a cut-off threshold of 50%.

    Further development is encouraged , specifically around the
    evaluation of various modeling methodologies (not just LDA) for each
    scenario to identify models which produce the best results under
    k-fold cross validation. The use of workflows::workflowsets() is
    encouraged. Since models are created at the scenario-level, optimal
    performance may result in instance where scenarios are associated
    with different model types.

    Furthermore, only distance metrics are currently being used to build
    models. However, “degrade\_\*.R” scripts contain placeholders for
    the quantification of pre-degradation names. Once a corresponding
    helper function is developed and integrated into “degrade\_\*.R”
    scripts, corresponding features can and should be integrated into
    modeling procedures.

    Once models are developed, a segmented sample of degradations are
    written to “path-file”. This contains pre- and post-degradation
    names for each sample and a “client\_feedback” field. This field
    should be populated with a “yes” / “no” response to indicate whether
    a the client believes that the degraded name should generate a match
    against the original name under in a properly calibrate system.

    Screening model results are compared to client-feedback using the
    McNemar paired-sample test to determine whether there is a
    statistical difference between screening model results and client
    expectations. If there is no statistical difference then scenario
    performance is update to “sufficient”; if there is a statistical
    difference, then scenario performance is updated to “deficient”.

    Under demo-mode conditions, scenario-models are utilize a simulate
    client feedback. Models are refitted with a higher cut-off threshold
    (e.g. 80%, such that probability of expecting a true-positive match
    should be greater than &gt;80% for a “yes” response to be
    generated), resulting in models with a lower AUC score to produce
    “deficient” results for some scenarios.

    Further development opportunities includes classification
    probability weighted sampling to better tailor the sample to select
    samples near the decision boundary.

11. **(… TODO …)  
    **A script to generate a file performance markdown report that
    summarizes scenario performance, modeling results, etc.

### Parameter Definitions

**\*\*TODO\*\*** Parameters currently reside in ‘\_main.R’; once
finalized, parameters should be relocated to the project’s R Environment
File.

-   **param.demo\_mode**  
    TRUE/FALSE: Run in demo-mode?

-   **param.refresh\_watchlists  
    **TRUE/FALSE: Should watchlists be refreshed? FALSE-response is
    ignored if no watchlist data-files are found in the “ref-files/”
    directory. Additionally, ignored if demo-mode is being run, unless
    no watchlist data-files are found.

-   **param.apply\_fml  
    **TRUE/FALSE: Should individual names be reformatted in the “First
    Middle Last” format? Assumes original names are in “LAST, First
    Middle” format and individual names are identified via \[SDN\_TYPE\]
    field; corresponding “\_main.R” reformatting logic may need to be
    updated if non-OFAC lists are integrated.

-   **param.drop\_middle\_names  
    **TRUE/FALSE: Should middle names be dropped?

-   **param.ignore\_alt\_names  
    **TRUE/FALSE: Should AKA entries be ignored for degradation-creation
    purposes? Corresponding “\_main.R” logic may need to be updated if
    non-OFAC lists are integrated.

-   **param.perf\_thld\_high  
    **\[0,1\]: Decimal from zero (0) to one (1) representing the cut-off
    percentage for judging a scenario’s performance to be “sufficient”.
    Recommended value in the \[0.85, 0.95\] range.

-   **param.perf\_thld\_low  
    **\[0,1\]: Decimal from zero (0) to one (1) representing the cut-off
    percentage for judging a scenario’s performance to be “deficient”.
    Recommended value in the \[0.60, 0.70\] range.

### Reference Files

-   **synonyms\_business-designations.txt  
    **Pipe-delimited file of business designation equivalents. All
    entries on the same line are judged to be equivalent. New entries
    should added with all punctuation variants (e.g. “LLC”, “L.L.C.”) to
    comply with ‘degrade\_entities.R’’ fixed()-matching logic
    requirements.

-   **stripping\_map.R  
    **Returns list-var “strip\_map” list with mapping between ASCII
    alphabetic characters and symbolic equivalents.

-   **country\_name\_fix.csv  
    **Sets equivalencies between OFAC list entry country names and
    ISO3166 country names to facilitate ‘pull-parse-enrich\_sdn-files.R’
    and ‘pull-parse-enrich\_cons-files.R’ enrichment of geographic data
    using 3rd party sources.

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

    -   **Concatenations  
        **Removes all white-space characters from names. (e.g. “John
        Howard Smith” to “JohnHowardSmith”).

    -   **Sticky Tokens  
        **Randomly removes one or more white-spaces from names
        (e.g. “John Howard Smith” to “JohnHoward Smith”).

    -   **Symbol Stripping  
        **Randomly replaces one or more characters with symbolic near
        equivalents, as defined by the “…path-file…” reference file
        (e.g. “John Howard Smith” to “John H0w@rd $mith”)

    -   **Long Name Truncation  
        **Truncates names over a specified character length to that
        length; currently set to 35-characters, per FedWire field-length
        limit.

    -   **Random Word Truncation  
        **Randomly truncates one or more tokens in a name to a random
        length (e.g. “John Howard Smith” to “Jo Howard Smit”).

    -   **Random Token Drop  
        **Randomly removes one or more tokens in name (e.g. “John Howard
        Smith” to “John Howard”).

-   **Entity Degradations:** ’ degrade\_entities.R’  
    Degradations applicable for only “entity” (e.g. businesses,
    organizations) type names, as defined in \[raw\].\[SDN\_TYPE\]
    field.

    *Scenarios are known to produce problematic output occationally and
    requires further logic development; for example, of “CO” is detected
    in the middle of a name, it may removed by the Remove Business
    Designation scenario (e.g. “Coca Cola Company” to “ca Cola
    Company”).*

    -   **Remove Business Designations  
        **Removes business designations (e.g. “John Smith Enterprises
        Limited Liability Company” to “John Smith Enterprises”).

    -   **Business Designation Synonyms  
        **Replaces business designation with synonyms, as defined in the
        “path-file” reference file. (e.g. “John Smith Enterprises
        Limited Liability Company” to “John Smith Enterprises LLC”).

    -   **Business Designation Replacement  
        **Replaces business designation with any other except synonyms,
        as defined in the “path-file” reference file. (e.g. “John Smith
        Enterprises Limited Liability Company” to “John Smith
        Enterprises INC”).

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

-   **splitName()  
    **Splits a “LAST, First Middle” formatted name into corresponding
    components. Assumes that first token in “First Middle” is the
    first-name and all other tokens correspond to the middle name. This
    is not accurate for multi-name first-names (e.g. "LAST, First1
    First2 Middle Middle), but judged to be a rare-occurrence; Logic can
    be refined if onomastic data and analysis is integrated.

-   **prettyName()  
    **Removes extraneous white-space and applies camel-case
    capitalization (e.g. “john HoWaRd SMITH” to “John Howard Smith”).

-   **gramify()  
    **Generates rolling n-grams for degradation distance calculations
    (e.g. “Johnathan” to {“Joh”, “ohn”, “hna”, “nat”, … } ).

-   **degDistance()  
    **Calculates degradation metrics for model performance modeling
    purposes.

-   **sample\_degradations\_simple()  
    **Used to filter and sample degradation logic output to generate an
    samples for screening.
