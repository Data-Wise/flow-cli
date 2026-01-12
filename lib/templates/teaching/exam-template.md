---
title: {{TOPIC}}
course: {{COURSE_NAME}}
duration: {{DURATION}} minutes
points: {{POINTS}}
instructions: |
  - You have {{DURATION}} minutes to complete this exam
  - Exam is worth {{POINTS}} points total
  - Show all work for partial credit
  - Read each question carefully
---

# {{TOPIC}}

**Course:** {{COURSE_NAME}}
**Name:** _______________________________
**Date:** _______________________________

**Duration:** {{DURATION}} minutes
**Total Points:** {{POINTS}}

---

## Instructions

- You have {{DURATION}} minutes to complete this exam
- Exam is worth {{POINTS}} points total
- Show all work for partial credit
- Read each question carefully
- Answer questions in the space provided

---

## Section 1: Multiple Choice (30 points)

*Choose the best answer for each question.*

1. [3 pts] What is the primary purpose of statistical hypothesis testing?
   - [ ] To prove that a hypothesis is true
   - [ ] To calculate the exact probability of an event
   - [x] To make decisions about population parameters based on sample data
   - [ ] To eliminate all sources of variability in data

2. [3 pts] In a regression analysis, what does R² represent?
   - [ ] The correlation coefficient
   - [ ] The standard error of the estimate
   - [x] The proportion of variance in Y explained by X
   - [ ] The slope of the regression line

3. [3 pts] Which assumption is NOT required for ANOVA?
   - [ ] Independence of observations
   - [ ] Normality of residuals
   - [ ] Homogeneity of variance
   - [x] Equal sample sizes across groups

---

## Section 2: Short Answer (40 points)

*Provide clear, concise answers in the space below each question.*

1. [10 pts] Explain the difference between Type I and Type II errors in hypothesis testing. Give an example of each in a real-world context.

   **Answer:**
   <!-- Student writes answer here -->

2. [10 pts] What is the Central Limit Theorem? Why is it important for statistical inference?

   **Answer:**
   <!-- Student writes answer here -->

3. [10 pts] Describe when you would use a paired t-test versus an independent samples t-test. Give an example scenario for each.

   **Answer:**
   <!-- Student writes answer here -->

4. [10 pts] What is the purpose of a confidence interval? How do you interpret a 95% confidence interval?

   **Answer:**
   <!-- Student writes answer here -->

---

## Section 3: Computational Problems (30 points)

*Show all work for full credit. Partial credit will be awarded for correct approach.*

### Problem 1 (15 points)

A researcher wants to test whether a new teaching method improves student test scores. A random sample of 25 students using the new method scored an average of 78 with a standard deviation of 12. The population mean for the traditional method is 72.

**Part a (5 pts):** State the null and alternative hypotheses.

**Part b (5 pts):** Calculate the test statistic.

**Part c (5 pts):** At α = 0.05, what is your conclusion? Show your work.

**Solution:**
<!-- Student shows work here -->

---

### Problem 2 (15 points)

The following data shows the number of hours studied and exam scores for 5 students:

| Hours Studied | Exam Score |
|---------------|------------|
| 2             | 65         |
| 4             | 75         |
| 6             | 85         |
| 8             | 90         |
| 10            | 95         |

**Part a (5 pts):** Calculate the correlation coefficient between hours studied and exam score.

**Part b (5 pts):** Fit a simple linear regression model. What is the equation?

**Part c (5 pts):** Interpret the slope coefficient in context.

**Solution:**
<!-- Student shows work here -->

---

## Answer Key (Instructor Only)

*This section should be removed before distributing to students.*

### Section 1: Multiple Choice

1. **C** - To make decisions about population parameters based on sample data
   - Hypothesis testing provides a framework for decision-making under uncertainty

2. **C** - The proportion of variance in Y explained by X
   - R² ranges from 0 to 1, with higher values indicating better model fit

3. **D** - Equal sample sizes across groups
   - ANOVA is robust to unequal sample sizes as long as other assumptions are met

**Section Total: 9/30 points**

---

### Section 2: Short Answer

1. **Type I vs Type II Errors (10 pts)**

   **Expected Answer:**
   - Type I Error: Rejecting H₀ when it's true (false positive)
   - Type II Error: Failing to reject H₀ when it's false (false negative)
   - Example: Medical test where Type I = diagnosing disease when absent, Type II = missing actual disease

   **Rubric:**
   - Definition of Type I (3 pts)
   - Definition of Type II (3 pts)
   - Real-world example (4 pts)

2. **Central Limit Theorem (10 pts)**

   **Expected Answer:**
   - CLT states that sampling distribution of mean approaches normal as n increases
   - Important because it allows us to use normal distribution for inference regardless of population distribution
   - Typically applies when n ≥ 30

   **Rubric:**
   - Statement of CLT (4 pts)
   - Importance for inference (4 pts)
   - Sample size consideration (2 pts)

3. **Paired vs Independent t-tests (10 pts)**

   **Expected Answer:**
   - Paired: Same subjects measured twice (before/after, matched pairs)
   - Independent: Different subjects in each group (treatment vs control)
   - Examples: Paired = weight before/after diet, Independent = test scores between two classes

   **Rubric:**
   - Paired t-test description (3 pts)
   - Independent t-test description (3 pts)
   - Examples (4 pts)

4. **Confidence Intervals (10 pts)**

   **Expected Answer:**
   - Range of plausible values for population parameter
   - 95% CI means if we repeated sampling, 95% of intervals would contain true parameter
   - NOT: "95% probability parameter is in this interval"

   **Rubric:**
   - Purpose (4 pts)
   - Correct interpretation (4 pts)
   - Common misconception avoided (2 pts)

**Section Total: 40/40 points**

---

### Section 3: Computational Problems

**Problem 1 (15 pts)**

**Part a (5 pts):**
- H₀: μ = 72 (new method doesn't improve scores)
- H₁: μ > 72 (new method improves scores)

**Part b (5 pts):**
- t = (x̄ - μ₀) / (s/√n)
- t = (78 - 72) / (12/√25)
- t = 6 / 2.4
- t = 2.5

**Part c (5 pts):**
- df = 24, critical value ≈ 1.711 (one-tailed)
- t = 2.5 > 1.711
- Reject H₀
- Conclusion: Evidence suggests new method improves scores (p < 0.05)

**Problem 2 (15 pts)**

**Part a (5 pts):**
- r = 0.996 (strong positive correlation)
- Calculation shown with Σxy, Σx, Σy, etc.

**Part b (5 pts):**
- ŷ = 55 + 4x
- where x = hours studied, y = exam score

**Part c (5 pts):**
- For each additional hour studied, exam score increases by 4 points on average
- Interpretation in context of problem

**Section Total: 30/30 points**

---

**Exam Total: {{POINTS}}/{{POINTS}} points**
