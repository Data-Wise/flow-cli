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

1. [MC] What is the primary purpose of statistical hypothesis testing? [3pts]
a) To prove that a hypothesis is true
b) To calculate the exact probability of an event
c) To make decisions about population parameters based on sample data [x]
d) To eliminate all sources of variability in data

2. [MC] In a regression analysis, what does R² represent? [3pts]
a) The correlation coefficient
b) The standard error of the estimate
c) The proportion of variance in Y explained by X [x]
d) The slope of the regression line

3. [MC] Which assumption is NOT required for ANOVA? [3pts]
a) Independence of observations
b) Normality of residuals
c) Homogeneity of variance
d) Equal sample sizes across groups [x]

4. [MC] What is a p-value? [3pts]
a) The probability that the null hypothesis is true
b) The probability of observing data as extreme as ours, given H₀ is true [x]
c) The probability that our results are due to chance
d) The significance level of the test

5. [MC] Which of the following increases statistical power? [3pts]
a) Smaller sample size
b) Smaller effect size
c) Larger sample size [x]
d) Higher significance level (α)

6. [MC] In a confidence interval, what does the confidence level represent? [3pts]
a) The probability the parameter is in this specific interval
b) The proportion of intervals that contain the parameter in repeated sampling [x]
c) The probability our estimate is correct
d) The margin of error

7. [MC] What is the purpose of randomization in experiments? [3pts]
a) To make the experiment easier to conduct
b) To reduce bias and balance confounding variables [x]
c) To ensure equal sample sizes
d) To eliminate all variability

8. [MC] Which distribution is used for t-tests? [3pts]
a) Normal distribution
b) Chi-square distribution
c) t-distribution [x]
d) F-distribution

9. [MC] What does it mean if a 95% CI for the difference in means includes zero? [3pts]
a) There is definitely no difference
b) We cannot reject H₀ at α = 0.05 [x]
c) The means are exactly equal
d) Our sample size was too small

10. [MC] What is the relationship between α and Type I error rate? [3pts]
a) They are unrelated
b) α sets the maximum Type I error rate we're willing to accept [x]
c) α is always larger than Type I error rate
d) Type I error rate determines α

---

## Section 2: Short Answer (40 points)

*Provide clear, concise answers in the space below each question.*

1. [Essay] Explain the difference between Type I and Type II errors in hypothesis testing. Give an example of each in a real-world context. [10pts]

2. [Essay] What is the Central Limit Theorem? Why is it important for statistical inference? [10pts]

3. [Essay] Describe when you would use a paired t-test versus an independent samples t-test. Give an example scenario for each. [10pts]

4. [Essay] What is the purpose of a confidence interval? How do you interpret a 95% confidence interval? [10pts]

---

## Section 3: Computational Problems (30 points)

*Show all work for full credit. Partial credit will be awarded for correct approach.*

### Problem 1 (15 points)

A researcher wants to test whether a new teaching method improves student test scores. A random sample of 25 students using the new method scored an average of 78 with a standard deviation of 12. The population mean for the traditional method is 72.

1. [Essay] State the null and alternative hypotheses. [5pts]

2. [Num] Calculate the test statistic. Round to 2 decimal places. [5pts]

3. [Essay] At α = 0.05, what is your conclusion? Show your work and explain your reasoning. [5pts]

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

1. [Num] Calculate the correlation coefficient between hours studied and exam score. Round to 3 decimal places. [5pts]

2. [Essay] Fit a simple linear regression model. What is the equation? Show your work. [5pts]

3. [Essay] Interpret the slope coefficient in context. [5pts]

---

## Answer Key (Instructor Only)

*Remove this section before distributing to students. For Canvas QTI export, this section is automatically excluded from student view.*

### Section 1: Multiple Choice Answers

1. **C** - To make decisions about population parameters based on sample data
   - Hypothesis testing provides a framework for decision-making under uncertainty

2. **C** - The proportion of variance in Y explained by X
   - R² ranges from 0 to 1, with higher values indicating better model fit

3. **D** - Equal sample sizes across groups
   - ANOVA is robust to unequal sample sizes as long as other assumptions are met

4. **B** - The probability of observing data as extreme as ours, given H₀ is true
   - Common misconception: p-value is NOT probability H₀ is true

5. **C** - Larger sample size
   - Power = 1 - β, increases with n, effect size, and α

6. **B** - The proportion of intervals that contain the parameter in repeated sampling
   - Frequentist interpretation, not about this specific interval

7. **B** - To reduce bias and balance confounding variables
   - Randomization helps create comparable groups

8. **C** - t-distribution
   - Used when population SD is unknown and estimated from sample

9. **B** - We cannot reject H₀ at α = 0.05
   - Zero is a plausible value for the difference

10. **B** - α sets the maximum Type I error rate we're willing to accept
    - α = P(reject H₀ | H₀ is true)

**Section 1 Total: 30/30 points**

---

### Section 2: Short Answer Rubrics

#### Question 1: Type I vs Type II Errors (10 pts)

**Expected Answer:**
- Type I Error: Rejecting H₀ when it's true (false positive) - 3 pts
- Type II Error: Failing to reject H₀ when it's false (false negative) - 3 pts
- Real-world example with both error types explained - 4 pts

**Example:** Medical test where Type I = diagnosing disease when absent (unnecessary treatment), Type II = missing actual disease (lack of treatment)

#### Question 2: Central Limit Theorem (10 pts)

**Expected Answer:**
- CLT states that sampling distribution of mean approaches normal as n increases - 4 pts
- Important because it allows us to use normal distribution for inference regardless of population distribution - 4 pts
- Typically applies when n ≥ 30 (or smaller if population is already normal) - 2 pts

#### Question 3: Paired vs Independent t-tests (10 pts)

**Expected Answer:**
- Paired: Same subjects measured twice (before/after, matched pairs) - 3 pts
- Independent: Different subjects in each group (treatment vs control) - 3 pts
- Appropriate examples for each - 4 pts

**Examples:**
- Paired = weight before/after diet, blood pressure before/after medication
- Independent = test scores between two different classes, height comparison male vs female

#### Question 4: Confidence Intervals (10 pts)

**Expected Answer:**
- Purpose: Range of plausible values for population parameter - 4 pts
- Correct interpretation: 95% CI means if we repeated sampling, 95% of intervals would contain true parameter - 4 pts
- Common misconception avoided: NOT "95% probability parameter is in this interval" - 2 pts

**Section 2 Total: 40/40 points**

---

### Section 3: Computational Problems Solutions

#### Problem 1 (15 pts)

**Part 1: Hypotheses (5 pts)**
- H₀: μ = 72 (new method doesn't improve scores) - 2.5 pts
- H₁: μ > 72 (new method improves scores, one-tailed) - 2.5 pts

**Part 2: Test Statistic (5 pts)**
- Formula: t = (x̄ - μ₀) / (s/√n) - 1 pt
- Calculation: t = (78 - 72) / (12/√25) - 2 pts
- t = 6 / 2.4 - 1 pt
- **Answer: t = 2.50** - 1 pt

**Part 3: Conclusion (5 pts)**
- df = 24, critical value ≈ 1.711 (one-tailed, α = 0.05) - 1 pt
- Comparison: t = 2.50 > 1.711 - 1 pt
- Decision: Reject H₀ - 1 pt
- Conclusion: Evidence suggests new method improves scores (p < 0.05) - 2 pts

#### Problem 2 (15 pts)

**Part 1: Correlation (5 pts)**
- Correct calculation setup with formula - 2 pts
- Σxy, Σx, Σy, Σx², Σy² computed - 2 pts
- **Answer: r = 0.996** (strong positive correlation) - 1 pt

**Part 2: Regression Equation (5 pts)**
- Slope calculation: b₁ = 4 - 2 pts
- Intercept calculation: b₀ = 55 - 2 pts
- **Answer: ŷ = 55 + 4x** - 1 pt

**Part 3: Interpretation (5 pts)**
- Identifies slope coefficient (4) - 1 pt
- States units clearly - 1 pt
- **Answer: "For each additional hour studied, exam score increases by 4 points on average"** - 3 pts
- Context of problem maintained

**Section 3 Total: 30/30 points**

---

**Exam Total: {{POINTS}}/{{POINTS}} points**

---

## Notes for Instructors

### Converting to Canvas QTI

This exam template is designed for Canvas LMS integration via examark:

```bash
# Convert to Canvas QTI format
examark exams/your-exam.md

# Verify output before upload
examark check exams/your-exam.md

# Test Canvas compatibility
examark emulate-canvas exams/your-exam.zip
```

### Question Type Tags

- `[MC]` - Multiple Choice (single answer)
- `[MA]` - Multiple Answers (select all that apply)
- `[TF]` - True/False
- `[Essay]` - Long-form text response
- `[Short]` - Short answer (fill-in-blank)
- `[Num]` - Numerical answer with tolerance

### Marking Correct Answers

Use `[x]` to mark correct answers in multiple choice:
```
a) Wrong answer
b) Correct answer [x]
c) Wrong answer
```

### Point Values

Specify points using `[Xpts]` format:
- `[3pts]` - Single point value
- `[2-5pts]` - Range for partial credit

### Canvas Import Instructions

1. Save this file (remove Answer Key section if desired)
2. Convert: `examark your-exam.md`
3. Canvas: Quizzes → Import → QTI 1.2
4. Upload the generated `.zip` file
5. Review and publish in Canvas

### Tips

- Test with `examark check` before converting
- Use `examark emulate-canvas` to preview Canvas import
- Keep question IDs unique across all questions
- Remove answer key section before student distribution
- Include clear instructions and point values
