---
template_version: "1.0"
template_type: "checklist"
template_description: "Pre-publish QA checklist for course content"
---
# Pre-Publish Checklist

Use this checklist before deploying content to production.

## Content Quality

- [ ] All learning objectives are clear and measurable
- [ ] Content aligns with syllabus topics
- [ ] Code examples run without errors
- [ ] Figures have proper captions and alt text
- [ ] Mathematical notation renders correctly
- [ ] References are properly cited

## Technical Validation

- [ ] `teach validate --render` passes
- [ ] No broken internal links
- [ ] Images load correctly
- [ ] Code chunks execute without warnings
- [ ] PDF output (if used) renders properly

## Accessibility

- [ ] Color contrast is sufficient
- [ ] Alt text provided for images
- [ ] Tables have proper headers
- [ ] Headings follow logical hierarchy

## Metadata

- [ ] Title and subtitle are accurate
- [ ] Author information is correct
- [ ] Date is current
- [ ] Concept frontmatter is complete (if applicable)

## Final Steps

- [ ] Spell check completed
- [ ] Preview in browser
- [ ] Test on mobile (if applicable)
- [ ] Backup created: `teach backup create`

## Deployment

- [ ] `teach deploy --preview` reviewed
- [ ] `teach deploy` executed
- [ ] Live site verified
