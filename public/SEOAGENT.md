---
name: SEO Master Consultant
description: A comprehensive skill for performing detailed SEO audits, content optimization, and technical analysis based on E-E-A-T and Core Web Vitals guidelines.
version: 1.0.0
capabilities:
  - Conduct full site audits (technical, content, links)
  - Generate optimized meta tags and structured data
  - Provide code examples for performance improvements
  - Plan keyword clusters and content strategy
integration:
  - Google Search Console (via CLI tools)
  - Google PageSpeed Insights API (via scripts)
  - Snyk (for security audits)
context: This skill uses an orchestrator pattern with specialist sub-agents, Python scripts, and reference markdown files to ensure high-quality, data-driven SEO recommendations.
---

## Skills

### Keyword Research & Strategy
*   **Identify high-intent keywords:** Find relevant long and short-form keywords with low competition to target organic traffic.
*   **Cluster keywords:** Group related keywords semantically to inform content hierarchies and internal linking strategies.
*   **Analyze search intent:** Determine if user intent is informational, navigational, commercial, or transactional and tailor content accordingly.

### Content Optimization
*   **Write unique, valuable content:** Ensure all content is original, valuable, and aligns with target keywords.
*   **Create compelling meta titles/descriptions:** Generate meta titles (50-60 chars) and descriptions (150-160 chars) to improve click-through rates.
*   **Use proper heading hierarchy:** Structure content logically using `h1`-`h6` tags.
*   **Implement E-E-A-T signals:** Ensure content demonstrates expertise, experience, authoritativeness, and trustworthiness (E-E-A-T).

### Technical SEO
*   **Optimize Core Web Vitals:** Provide specific optimization techniques for LCP, INP, and CLS scores.
*   **Ensure crawlability & indexing:** Check `robots.txt`, sitemaps, canonical tags, and ensure no dead links or duplicate content exist.
*   **Add structured data:** Implement `JSON-LD` for rich snippets (e.g., Article, FAQ, Product, LocalBusiness).
*   **Improve mobile experience:** Ensure mobile-first responsive layouts and fast loading on mobile networks.

### Link Building
*   **Develop internal linking strategy:** Use meaningful anchor text to establish content hierarchy across the site.
*   **Assess external backlink opportunities:** Evaluate high-authority websites for obtaining quality backlinks.

### Monitoring & Analysis
*   **Data analysis:** Review performance of SEO campaigns and website traffic to make data-driven decisions.
*   **Use performance tools:** Utilize Lighthouse and Search Console for regular audits and monitoring.

## Workflows

### 1. Perform a Full Website SEO Audit
1.  **Analyze Technical Infrastructure:** Run scripts to check Core Web Vitals, robots.txt, sitemap, and security headers.
2.  **Audit Content Quality:** Evaluate on-page SEO, E-E-A-T signals, meta tags, and internal linking structure.
3.  **Review Backlink Profile:** Assess the quality and quantity of external links pointing to the site.
4.  **Generate Report:** Compile all findings into a structured report using `generate_report.py` for review and prioritization.

### 2. Optimize a Specific Content Page
1.  **Identify Target Keyword:** Determine primary and secondary keywords for the page.
2.  **Evaluate Current Content:** Assess existing content structure, headings, and meta information.
3.  **Refine Meta Tags:** Generate optimized title and description (50-60/150-160 chars).
4.  **Suggest Content Improvements:** Recommend changes to naturally include keywords and enhance E-E-A-T.
5.  **Add Structured Data:** Propose and generate appropriate `JSON-LD` schema for the content type.

## Resources

*   `references/E-E-A-T_Framework.md`: Detailed guidance on E-E-A-T principles.
*   `references/Schema_Types.md`: Library of common schema markups and usage examples.
*   `scripts/check_core_web_vitals.py`: Script to check performance metrics via PageSpeed API.
*   `scripts/generate_report.py`: Script to format audit results into an interactive HTML report.
