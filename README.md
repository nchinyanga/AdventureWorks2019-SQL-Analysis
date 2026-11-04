# AdventureWorks2019 Sales Analysis Using SQL

An end-to-end SQL analysis of the Microsoft **AdventureWorks2019** sample database, built with **SQL Server and T-SQL**. The project turns transactional sales data into business insight by answering **33 business questions** across six analytical areas.



---

## Table of Contents

- [Project Overview](#project-overview)
- [Objectives](#objectives)
- [Tools and Technologies](#tools-and-technologies)
- [Database Structure](#database-structure)
- [Methodology](#methodology)
- [Business Questions](#business-questions)
- [Key Findings](#key-findings)
- [Limitations](#limitations)
- [Repository Structure](#repository-structure)
- [How to Reproduce](#how-to-reproduce)
- [Next Steps](#next-steps)

---

## Project Overview

The analysis covers sales from **31 May 2011 to 30 June 2014** and focuses on:

1. Sales Performance
2. Profitability Analysis
3. Product Performance
4. Customer Analysis
5. Geographical Performance
6. Sales Channel Analysis

**Status:** SQL analysis completed.

## Objectives

- Evaluate overall sales performance and revenue trends
- Assess estimated gross profit and gross margins
- Identify high-performing and underperforming products
- Understand customer purchasing behaviour and revenue concentration
- Evaluate performance across geographical territories
- Compare online and non-online sales
- Investigate unusual sales patterns and potential business risks

## Tools and Technologies

| Technology | Purpose |
|---|---|
| Microsoft SQL Server | Database environment |
| SQL Server Management Studio (SSMS) | SQL development and analysis |
| T-SQL | Extraction, transformation, aggregation and analysis |
| AdventureWorks2019 | Source relational database |

## Database Structure

The analysis primarily uses tables from the `Sales` and `Production` schemas.

| Table | Purpose |
|---|---|
| `Sales.SalesOrderHeader` | Order-level information |
| `Sales.SalesOrderDetail` | Product-level transaction information |
| `Sales.Customer` | Customer information |
| `Sales.SalesTerritory` | Geographical territory information |
| `Production.Product` | Product attributes and standard costs |
| `Production.ProductSubcategory` | Product subcategory classification |
| `Production.ProductCategory` | Product category classification |
| `Sales.SpecialOfferProduct` | Product promotion information |

**Key relationships**

- `SalesOrderHeader` → `SalesOrderDetail` via `SalesOrderID`
- `SalesOrderHeader` → `Customer` via `CustomerID`
- `SalesOrderDetail` → `Product` via `ProductID`
- `Product` → `ProductSubcategory` via `ProductSubcategoryID`
- `ProductSubcategory` → `ProductCategory` via `ProductCategoryID`
- `SalesOrderHeader` → `SalesTerritory` via `TerritoryID`

For geographical analysis, the territory recorded on the sales order represents the transaction's location.

## Methodology

1. **Database exploration:** schemas, tables, columns and relationships
2. **Data profiling:** record counts, date ranges, distinct customers and products, order status
3. **Business question development:** 33 questions across six areas
4. **Query development:** joins, aggregations, conditional expressions, CTEs and window functions
5. **Metric calculation:** revenue, orders, quantities, AOV, estimated costs and margins
6. **Validation:** reconciliation and follow-up queries on unexpected results
7. **Business interpretation:** translating results into findings and areas for further investigation

**SQL techniques used:** `INNER JOIN` / `LEFT JOIN`, `GROUP BY` and aggregates, `CASE WHEN`, CTEs, subqueries, window functions (ranking), `COUNT(DISTINCT ...)`, `SUM()` / `AVG()`, date functions and period comparisons, conditional aggregation, percentage and growth calculations.

## Business Questions

| Area | Questions | Main focus |
|---|---|---|
| Sales Performance | BQ01–BQ06 | Revenue, orders, units, AOV, annual trends |
| Profitability | BQ07–BQ12 | Estimated COGS, gross profit, margins, discounts |
| Product Performance | BQ13–BQ17 | Product revenue, units, category contribution |
| Customer Analysis | BQ18–BQ23 | Segmentation, repeat purchasing, revenue concentration |
| Geographical Performance | BQ24–BQ28 | Territory revenue, profitability, growth |
| Sales Channels | BQ29–BQ33 | Online vs non-online performance |

---

## Key Findings

### Sales Performance

| Metric | Result |
|---|---:|
| Total net line revenue | $109,846,381.40 |
| Total orders | 31,465 |
| Total order lines | 121,317 |
| Units sold | 274,914 |
| Unique purchasing customers | 19,119 |
| Unique products sold | 266 |
| Average order value | $3,491.07 |

| Year | Revenue | Orders | Units | AOV | Revenue Growth |
|---|---:|---:|---:|---:|---:|
| 2011 | $12.64M | 1,607 | 12,888 | $7,866.63 | — |
| 2012 | $33.52M | 3,915 | 68,579 | $8,563.04 | 165.19% |
| 2013 | $43.62M | 14,182 | 131,788 | $3,075.90 | 30.12% |
| 2014 | $20.06M | 11,761 | 61,659 | $1,705.46 | -54.02% |

- 2013 was the highest revenue year (~$43.62M).
- 2014 covers January–June only. A like-for-like first-half comparison shows revenue **+7.40%**, orders **+329.08%**, units **+20.02%** and AOV **-74.97%** versus 2013.

> **June 2014 anomaly:** revenue of $49,005.84 across 939 orders (AOV $52.19), all online, with no bicycle sales: accessories and clothing only. Revenue fell ~97.5% versus May 2014. The cause cannot be established from the database and needs further investigation.

### Profitability (estimated)

| Metric | Result |
|---|---:|
| Revenue | $109,846,381.40 |
| Estimated COGS | $100,474,477.77 |
| Estimated gross profit | $9,371,903.63 |
| Estimated gross margin | 8.53% |

| Category | Revenue | Est. Gross Profit | Est. Margin |
|---|---:|---:|---:|
| Bikes | $94,651,172.70 | $7,936,394.02 | 8.38% |
| Accessories | $1,272,072.88 | $636,394.26 | 50.03% |
| Components | $11,802,593.29 | $490,233.18 | 4.15% |
| Clothing | $2,120,542.52 | $308,882.17 | 14.57% |

- Bikes drive ~86.17% of revenue; Accessories have the highest margin (50.03%); Components have high revenue but a thin 4.15% margin.
- **57 products** recorded negative estimated gross profit (e.g. Road-650 Red 44 at -$153,696.12, Touring-1000 Yellow 60 at -$132,745.72).
- Discounted lines (3,282 lines, ~$5.42M revenue) recorded estimated gross profit of -$1,893,074.94. This is an association, not proof that discounts caused the weak margins.

### Product Performance

- Mountain-200 variants generated ~**$22.29M**.
- Bikes: 86.17% of revenue but only 32.84% of units.
- Clothing: 26.80% of units but 1.93% of revenue. Accessories: 22.53% of units but 1.16% of revenue.
- Road Bikes ~$43.91M, Mountain Bikes ~$36.45M, Touring Bikes ~$14.30M.
- Top by units: AWC Logo Cap (8,311), Water Bottle 30 oz (6,815).

High-volume products are not necessarily the largest revenue contributors, so both measures matter.

### Customer Analysis

| Metric | Result |
|---|---:|
| Registered customers | 19,820 |
| Purchasing customers | 19,119 |
| Customers without recorded purchases | 701 |
| Repeat customers | 7,470 |
| One-time customers | 11,649 |

- Repeat customers generated ~$103.08M (**93.84%** of revenue).
- The top 100 customers contributed **42.31%** of revenue (~0.52% of registered customers); the top 10 contributed ~$7.92M (7.21%).
- Customer types (via `PersonID` / `StoreID`): Individual 18,484, Business-only 701, Both 635.

### Geographical Performance

| Territory | Revenue | Share | Est. Margin | H1 2013→2014 Growth |
|---|---:|---:|---:|---:|
| Southwest | $24.18M | 22.02% | 6.47% | -4.51% |
| Canada | $16.36M | 14.89% | 2.47% | -18.98% |
| Northwest | $16.08M | 14.64% | 8.48% | 28.98% |
| Australia | $10.66M | 9.70% | 32.23% | 90.42% |

- Strongest margins: Australia (32.23%), Germany (21.22%), United Kingdom (16.06%).
- Negative margins: Central (-1.80%), Southeast (-1.92%), Northeast (-3.88%).
- Fastest growth: Australia (90.42%), Germany (79.83%), United Kingdom (73.18%). Steepest decline: Northeast (-47.58%).

### Sales Channel Analysis

| Metric | Online | Non-Online |
|---|---:|---:|
| Orders | 27,659 | 3,806 |
| Order share | 87.90% | 12.10% |
| Customers | 18,484 | 635 |
| Units sold | 60,398 | 214,516 |
| Revenue | $29.36M | $80.49M |
| Revenue share | 26.73% | 73.27% |
| Average order value | $1,061.45 | $21,147.58 |
| Est. gross profit | $11.69M | -$2.32M |
| Est. gross margin | 39.81% | -2.88% |

- Online drives most orders but a minority of revenue; non-online drives most revenue at a negative estimated margin, concentrated in Bikes (-4.79% vs 39.24% for online Bikes).
- **Confounding:** validation showed customer type and sales channel align exactly. All 635 "Both" customers and all 3,806 non-online orders go together, as do all 18,484 Individual customers and all 27,659 online orders. The analysis therefore cannot separate which factor explains the price and margin differences.

---

## Limitations

1. **Estimated profitability:** `StandardCost` is a proxy for historical cost, so margins are estimates, not audited accounting results.
2. **Incomplete years:** 2011 and 2014 are partial years; first-half comparisons are used where appropriate.
3. **June 2014 anomaly:** cause not established from the available data.
4. **Discounts:** the link to lower margins is not causal evidence.
5. **Channel classification:** non-online transactions should not automatically be treated as wholesale or B2B.
6. **Customer classification:** `PersonID` / `StoreID` describe record structure, not the commercial nature of every order.
7. **Customers without orders:** should not automatically be labelled as churned.

## Repository Structure

```text
AdventureWorks2019-SQL-Analysis/
│
├── README.md
│
├── SQL/
   ├── 01_Data_Exploration.sql
   ├── 02_Sales_Performance.sql
   ├── 03_Profitability_Analysis.sql
   ├── 04_Product_Performance.sql
   ├── 05_Customer_Analysis.sql
   ├── 06_Geographical_Analysis.sql
   └── 07_Sales_Channel_Analysis.sql


```

## How to Reproduce

1. Install **SQL Server** and **SSMS**.
2. Restore the **AdventureWorks2019** backup from the [Microsoft sample databases page].
3. Open the scripts in `SQL/` in SSMS against the `AdventureWorks2019` database.
4. Run the scripts in numerical order (`01` to `07`).

## Next Steps

- Build a Power BI dashboard on top of these findings.
- Investigate the June 2014 sales anomaly and the 57 negative-margin products.
- Re-test price and margin differences where customer type and channel can be separated.

---

**Project:** AdventureWorks2019 Sales Analysis Using SQL
**Database:** Microsoft AdventureWorks2019
**Tools:** SQL Server, SSMS, T-SQL
**Analysis:** 33 business questions across six analytical areas
**Author:** *Nyasha Chinyanga / https://github.com/nchinyanga/insightdrive / *
