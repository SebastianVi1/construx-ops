# Material prices are organization-scoped and recorded, not scraped

Status: accepted (2026-10-27)

Each organization keeps its own catalog of Materials, Suppliers and Price observations. Prices enter only by manual entry or CSV import, with the source stored on each observation. Prices are MXN, shelf price including IVA.

Why: the first market is Mexico, and Home Depot México has no public price API. Scraping it breaks its terms of use and fights its bot protection, so the feature would be fragile and a legal risk for a commercial SaaS. Negotiated supplier prices are also commercially sensitive to each company.

Considered and rejected: a scheduled scraper of Home Depot MX; third-party price APIs (SerpApi, BigBox), which cover Home Depot US only; one global catalog shared by all organizations, which needs a platform curator Construx does not have and would leak one company's prices to the others.

Consequences: a future automated source (an API or a licensed feed) is added as another observation source, not as a change to the model. Prices are only as fresh as the company keeps them, so the UI marks prices older than 90 days as stale.
