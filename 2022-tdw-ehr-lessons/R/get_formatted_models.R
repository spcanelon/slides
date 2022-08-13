# regarding mutate across with ifelse(): https://stackoverflow.com/a/65712037

# NOTES: NAs in Excel sheet are coded as numeric -1010
# Inf in Excel sheet are coded as numeric 1010
# blanks in Excel sheet are just empty

get_formatted_models <- function(name_file) {
  name_file <- paste0(name_file, ".xlsx", sep = "")

  my_df <-
    readxl::read_excel(
      here::here("data",
                 name_file)) %>%
    mutate(across(.cols = c(aOR, `2.5`, `97.5`, PVALUE), as.numeric)) %>%
    mutate(`97.5` = ifelse(`97.5` == Inf, 1010, `97.5`)) %>%
    mutate(SIG = case_when(
      PVALUE < 0.001 & PVALUE != -1010 & aOR != "" ~ "***",
      PVALUE < 0.01 & PVALUE != -1010 & aOR != "" ~ "**",
      PVALUE < 0.05 & PVALUE != -1010 & aOR != "" ~ "*",
      TRUE ~ "" )) %>%
    #filter(!((PVALUE >= 0.05 | PVALUE == -1010) & !is.na(aOR))) %>%
    select(-c(STD_ERROR, STATISTIC))

  #return(my_df)

  OUTCOME <- my_df

  # indent the subgroup if it's not labeled as "Group"
  OUTCOME$Predictor <-
    ifelse(OUTCOME$FORMAT == "Group",
           OUTCOME$Predictor,
           paste0("   ", OUTCOME$Predictor))

  aOR_CI <-
    OUTCOME %>% select(aOR, `2.5`, `97.5`, PVALUE, SIG) %>%
    mutate(across(.cols = aOR:PVALUE, as.numeric)) %>%
    mutate(across(.cols = everything(), ~ifelse(.x > 100, 1010, .x))) %>%
    mutate(across(.cols = aOR:`97.5`, round, 2)) %>%
    mutate(across(.cols = PVALUE, round, 3)) %>%
    mutate(across(.cols = aOR:`97.5`, format, nsmall = 2, trim = TRUE)) %>%
    mutate(across(.cols = everything(), ~ifelse(.x == "NA", "", .x))) %>%
    mutate(across(.cols = everything(), ~ifelse(.x == "1010.00", ">100", .x))) %>%
    mutate(new = glue::glue("{aOR} ({`2.5`} to {`97.5`}) {SIG}", .na = "")) %>%
    mutate(new = as.character(new)) %>%
    transmute(new = case_when(
      new == " ( to ) " ~ "",
      new == "-1010.00 (-1010.00 to -1010.00) " ~ "Not Available",
      TRUE ~ new)) %>%
    rename("Adjusted OR & 95% CI" = new)

  #return(aOR_CI)

  outcome_aOR_CI <- cbind(my_df, aOR_CI)
  return(outcome_aOR_CI)
}
