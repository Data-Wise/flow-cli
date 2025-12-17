# R Style Guide

> **TL;DR:** Follow tidyverse style. Use `styler` to auto-format. Use `lintr` to check.

## Quick Setup

```r
# Install tools
install.packages(c("styler", "lintr"))

# Auto-format a file
styler::style_file("R/my_function.R")

# Auto-format entire package
styler::style_pkg()

# Check for issues
lintr::lint_package()
```

## The Rules

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Functions | `snake_case` | `calculate_effect()` |
| Variables | `snake_case` | `sample_size` |
| Constants | `SCREAMING_SNAKE` | `MAX_ITERATIONS` |
| S3 classes | `snake_case` | `mediation_result` |
| S4 classes | `PascalCase` | `MediationModel` |
| File names | `snake_case.R` | `bootstrap_ci.R` |

### Spacing

```r
# GOOD
x <- 5
y <- c(1, 2, 3)
z <- function(a, b) a + b

# BAD
x<-5
y<-c(1,2,3)
z<-function(a,b) a+b
```

### Line Length

- **Maximum:** 80 characters
- **Preferred:** Under 72 for readability
- Break long lines at operators or commas

```r
# GOOD
result <- very_long_function_name(
  argument_one = value_one,
  argument_two = value_two,
  argument_three = value_three
)

# BAD
result <- very_long_function_name(argument_one = value_one, argument_two = value_two, argument_three = value_three)
```

### Functions

```r
# GOOD: Clear structure
calculate_indirect_effect <- function(a, b,
                                       bootstrap = TRUE,
                                       n_boot = 1000) {
  # Validate inputs
  stopifnot(is.numeric(a), is.numeric(b))

  # Calculate effect
  effect <- a * b

  # Bootstrap if requested
  if (bootstrap) {
    ci <- bootstrap_ci(effect, n_boot)
    return(list(effect = effect, ci = ci))
  }

  effect
}
```

### Comments

```r
# GOOD: Explain WHY, not WHAT
# Use bootstrap because asymptotic CI has poor coverage for small samples
ci <- bootstrap_ci(effect, n_boot = 1000)

# BAD: States the obvious
# Calculate the confidence interval
ci <- bootstrap_ci(effect, n_boot = 1000)
```

### roxygen2 Documentation

```r
#' Calculate indirect effect
#'
#' @description
#' Computes the product of coefficients for mediation analysis.
#'
#' @param a Numeric. Effect of X on M.
#' @param b Numeric. Effect of M on Y.
#' @param bootstrap Logical. Use bootstrap CI? Default TRUE.
#' @param n_boot Integer. Number of bootstrap samples.
#'
#' @return A list with effect estimate and confidence interval.
#'
#' @examples
#' calculate_indirect_effect(0.5, 0.3)
#' calculate_indirect_effect(0.5, 0.3, bootstrap = FALSE)
#'
#' @export
calculate_indirect_effect <- function(a, b, bootstrap = TRUE, n_boot = 1000) {
  # ...
}
```

### Package Structure

```
mypackage/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── mypackage-package.R    # Package docs
│   ├── main_function.R        # One function per file
│   ├── helper_functions.R     # Small helpers can share
│   └── utils.R                # Internal utilities
├── man/                       # Auto-generated
├── tests/
│   └── testthat/
│       ├── test-main_function.R
│       └── helper-test_utils.R
├── vignettes/
└── inst/
```

### Testing with testthat

```r
# tests/testthat/test-calculate_effect.R

test_that("calculate_indirect_effect returns correct value", {
  result <- calculate_indirect_effect(0.5, 0.4, bootstrap = FALSE)
  expect_equal(result, 0.2)
})

test_that("calculate_indirect_effect validates inputs", {
  expect_error(calculate_indirect_effect("a", 0.4))
  expect_error(calculate_indirect_effect(0.5, NULL))
})

test_that("bootstrap CI has expected length", {
  result <- calculate_indirect_effect(0.5, 0.4, bootstrap = TRUE)
  expect_length(result$ci, 2)
})
```

---

## Quick Reference Card

| Do This | Not This |
|---------|----------|
| `snake_case` | `camelCase` or `dot.case` |
| `<-` for assignment | `=` for assignment |
| Explicit `return()` | Implicit return |
| `TRUE`/`FALSE` | `T`/`F` |
| `seq_len(n)` | `1:n` when n could be 0 |
| `vapply()` | `sapply()` |
| `||` and `&&` | `|` and `&` for scalars |

## Tools

```bash
# Format before commit
Rscript -e "styler::style_pkg()"

# Check before push
Rscript -e "lintr::lint_package()"

# Or use aliases
alias rstyle='Rscript -e "styler::style_pkg()"'
alias rlint='Rscript -e "lintr::lint_package()"'
```

## Resources

- [Tidyverse Style Guide](https://style.tidyverse.org/)
- [R Packages Book](https://r-pkgs.org/)
- [Advanced R](https://adv-r.hadley.nz/)
