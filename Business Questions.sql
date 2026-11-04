--Objective 1: Executive sales performance summary
-- 1. Business question: What was AdventureWorks' overall sales performance during the available reporting period?

SELECT
    MIN(h.OrderDate) AS First_Order_Date,
    MAX(h.OrderDate) AS Last_Order_Date,

    SUM(d.LineTotal) AS Total_Revenue,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Total_Units_Sold,

    CAST(
        SUM(d.LineTotal) /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    COUNT(DISTINCT h.CustomerID) AS Unique_Customers,

    COUNT(DISTINCT d.ProductID) AS Unique_Products_Sold

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID;



-- Business question: How does sales revenue change from month to month, and are there periods of stronger or weaker sales performance?
SELECT
    YEAR(h.OrderDate) AS Sales_Year,

    MONTH(h.OrderDate) AS Sales_Month,

    DATENAME(MONTH, h.OrderDate) AS Month_Name,

    SUM(d.LineTotal) AS Monthly_Revenue,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.LineTotal) /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

GROUP BY
    YEAR(h.OrderDate),
    MONTH(h.OrderDate),
    DATENAME(MONTH, h.OrderDate)

ORDER BY
    Sales_Year,
    Sales_Month;





--- Business question: Is AdventureWorks growing its sales revenue from year to year?

WITH YearlySales AS
(
    SELECT
        YEAR(h.OrderDate) AS Sales_Year,

        SUM(d.LineTotal) AS Annual_Revenue,

        COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

        SUM(d.OrderQty) AS Units_Sold

    FROM Sales.SalesOrderHeader h

    INNER JOIN Sales.SalesOrderDetail d
        ON h.SalesOrderID = d.SalesOrderID

    GROUP BY YEAR(h.OrderDate)
)

SELECT
    Sales_Year,

    Annual_Revenue,

    Total_Orders,

    Units_Sold,

    CAST(
        Annual_Revenue / Total_Orders
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    LAG(Annual_Revenue) OVER (
        ORDER BY Sales_Year
    ) AS Previous_Year_Revenue,

    CAST(
        (
            Annual_Revenue -
            LAG(Annual_Revenue) OVER (
                ORDER BY Sales_Year
            )
        ) * 100.0
        /
        NULLIF(
            LAG(Annual_Revenue) OVER (
                ORDER BY Sales_Year
            ), 0
        )
        AS DECIMAL(10,2)
    ) AS Revenue_Growth_Percentage

FROM YearlySales

ORDER BY Sales_Year;




-- Business question: Did sales revenue improve or decline during the first six months of 2014 compared with the same period in 2013?

SELECT
    YEAR(h.OrderDate) AS Sales_Year,

    SUM(d.LineTotal) AS Revenue,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.LineTotal) /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

WHERE
    MONTH(h.OrderDate) BETWEEN 1 AND 6
    AND YEAR(h.OrderDate) IN (2013, 2014)

GROUP BY YEAR(h.OrderDate)

ORDER BY Sales_Year;


--- Business question: What do the individual orders in June 2014 look like, and are unusually small transactions driving the low average order value?

SELECT
    h.SalesOrderID,
    h.OrderDate,
    h.CustomerID,
    h.OnlineOrderFlag,
    h.SubTotal,
    COUNT(d.SalesOrderDetailID) AS Order_Lines,
    SUM(d.OrderQty) AS Units_Sold,
    SUM(d.LineTotal) AS Detail_Revenue

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

WHERE
    h.OrderDate >= '2014-06-01'
    AND h.OrderDate < '2014-07-01'

GROUP BY
    h.SalesOrderID,
    h.OrderDate,
    h.CustomerID,
    h.OnlineOrderFlag,
    h.SubTotal

ORDER BY
    h.SubTotal ASC;


-- Business question: Is the low average order value in June 2014 associated with the online sales channel?

SELECT
    CASE
        WHEN h.OnlineOrderFlag = 1
            THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.LineTotal) AS Total_Revenue,

    CAST(
        SUM(d.LineTotal) /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.OrderQty) * 1.0 /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(10,2)
    ) AS Average_Units_Per_Order

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

WHERE
    h.OrderDate >= '2014-06-01'
    AND h.OrderDate < '2014-07-01'

GROUP BY
    h.OnlineOrderFlag

ORDER BY
    h.OnlineOrderFlag;



-- Business question: Are most June orders very low-value, or is the low average being driven by a smaller number of unusual transactions?

WITH OrderValues AS
(
    SELECT
        h.SalesOrderID,
        h.SubTotal,

        CASE
            WHEN h.SubTotal < 100 THEN 'Below $100'
            WHEN h.SubTotal < 500 THEN '$100 - $499'
            WHEN h.SubTotal < 1000 THEN '$500 - $999'
            WHEN h.SubTotal < 5000 THEN '$1,000 - $4,999'
            ELSE '$5,000 and above'
        END AS Order_Value_Range

    FROM Sales.SalesOrderHeader h

    WHERE
        h.OrderDate >= '2014-06-01'
        AND h.OrderDate < '2014-07-01'
)

SELECT
    Order_Value_Range,

    COUNT(*) AS Number_of_Orders,

    SUM(SubTotal) AS Total_Revenue,

    CAST(
        AVG(SubTotal)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER()
        AS DECIMAL(10,2)
    ) AS Percentage_of_Orders

FROM OrderValues

GROUP BY Order_Value_Range

ORDER BY
    CASE Order_Value_Range
        WHEN 'Below $100' THEN 1
        WHEN '$100 - $499' THEN 2
        WHEN '$500 - $999' THEN 3
        WHEN '$1,000 - $4,999' THEN 4
        ELSE 5
    END;


-- Business question: Which products generated the most revenue and sales volume in June 2014?
SELECT
    p.ProductID,
    p.Name AS Product_Name,
    p.ProductNumber,

    COUNT(DISTINCT h.SalesOrderID) AS Number_of_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    SUM(d.LineTotal) AS Total_Revenue,

    CAST(
        AVG(d.UnitPrice)
        AS DECIMAL(18,2)
    ) AS Average_Unit_Price,

    CAST(
        AVG(d.UnitPriceDiscount) * 100
        AS DECIMAL(10,2)
    ) AS Average_Discount_Percent

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

WHERE
    h.OrderDate >= '2014-06-01'
    AND h.OrderDate < '2014-07-01'

GROUP BY
    p.ProductID,
    p.Name,
    p.ProductNumber

ORDER BY
    Total_Revenue DESC;


-- Business question: Did the business experience a shift from non-online to online sales between the two periods?

SELECT
    YEAR(h.OrderDate) AS Sales_Year,

    CASE
        WHEN h.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.LineTotal) AS Total_Revenue,

    CAST(
        SUM(d.LineTotal) /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    SUM(d.OrderQty) AS Units_Sold

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

WHERE
    (
        h.OrderDate >= '2013-06-01'
        AND h.OrderDate < '2013-07-01'
    )
    OR
    (
        h.OrderDate >= '2014-06-01'
        AND h.OrderDate < '2014-07-01'
    )

GROUP BY
    YEAR(h.OrderDate),
    h.OnlineOrderFlag

ORDER BY
    Sales_Year,
    h.OnlineOrderFlag;


-- Business question: Did the business move from selling high-value products, such as complete bicycles, towards lower-value accessories and components?

SELECT
    YEAR(h.OrderDate) AS Sales_Year,

    pc.Name AS Product_Category,

    ps.Name AS Product_Subcategory,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    SUM(d.LineTotal) AS Total_Revenue,

    CAST(
        SUM(d.LineTotal) /
        COUNT(DISTINCT h.SalesOrderID)
        AS DECIMAL(18,2)
    ) AS Revenue_Per_Order

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

WHERE
    h.OnlineOrderFlag = 1
    AND (
        (h.OrderDate >= '2013-06-01'
         AND h.OrderDate < '2013-07-01')
        OR
        (h.OrderDate >= '2014-06-01'
         AND h.OrderDate < '2014-07-01')
    )

GROUP BY
    YEAR(h.OrderDate),
    pc.Name,
    ps.Name

ORDER BY
    Sales_Year,
    Total_Revenue DESC;


-- Business question: Did bicycle sales suddenly disappear in June 2014, or had the decline already started?

SELECT
    YEAR(h.OrderDate) AS Sales_Year,
    MONTH(h.OrderDate) AS Sales_Month,
    pc.Name AS Product_Category,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    SUM(d.LineTotal) AS Total_Revenue

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

WHERE
    h.OnlineOrderFlag = 1
    AND h.OrderDate >= '2014-05-01'
    AND h.OrderDate < '2014-07-01'

GROUP BY
    YEAR(h.OrderDate),
    MONTH(h.OrderDate),
    pc.Name

ORDER BY
    Sales_Month,
    Total_Revenue DESC;

-- Business question: On which dates were bicycle sales last recorded in June 2014, and how did daily revenue behave?

SELECT
    CAST(h.OrderDate AS DATE) AS Order_Date,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    SUM(d.LineTotal) AS Total_Revenue,

    SUM(
        CASE
            WHEN pc.Name = 'Bikes'
            THEN d.OrderQty
            ELSE 0
        END
    ) AS Bicycle_Units_Sold,

    SUM(
        CASE
            WHEN pc.Name = 'Bikes'
            THEN d.LineTotal
            ELSE 0
        END
    ) AS Bicycle_Revenue

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

WHERE
    h.OrderDate >= '2014-06-01'
    AND h.OrderDate < '2014-07-01'
    AND h.OnlineOrderFlag = 1

GROUP BY
    CAST(h.OrderDate AS DATE)

ORDER BY
    Order_Date;


--- Business question: Were the bicycles that sold in May still listed as active products in June, or had their selling periods ended?

SELECT
    p.ProductID,
    p.Name AS Product_Name,
    p.ProductNumber,
    p.SellStartDate,
    p.SellEndDate,
    p.DiscontinuedDate,

    SUM(
        CASE
            WHEN h.OrderDate >= '2014-05-01'
             AND h.OrderDate < '2014-06-01'
            THEN d.OrderQty
            ELSE 0
        END
    ) AS May_Units_Sold,

    SUM(
        CASE
            WHEN h.OrderDate >= '2014-06-01'
             AND h.OrderDate < '2014-07-01'
            THEN d.OrderQty
            ELSE 0
        END
    ) AS June_Units_Sold

FROM Production.Product p

INNER JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

INNER JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

LEFT JOIN Sales.SalesOrderDetail d
    ON p.ProductID = d.ProductID

LEFT JOIN Sales.SalesOrderHeader h
    ON d.SalesOrderID = h.SalesOrderID
    AND h.OnlineOrderFlag = 1
    AND h.OrderDate >= '2014-05-01'
    AND h.OrderDate < '2014-07-01'

WHERE
    pc.Name = 'Bikes'

GROUP BY
    p.ProductID,
    p.Name,
    p.ProductNumber,
    p.SellStartDate,
    p.SellEndDate,
    p.DiscontinuedDate

HAVING
    SUM(
        CASE
            WHEN h.OrderDate >= '2014-05-01'
             AND h.OrderDate < '2014-06-01'
            THEN d.OrderQty
            ELSE 0
        END
    ) > 0

ORDER BY
    May_Units_Sold DESC;


-- Business question: What inventory quantities are currently recorded for the bicycle products that sold in May but recorded no sales in June?
WITH MayBicycleSales AS
(
    SELECT
        d.ProductID,
        SUM(d.OrderQty) AS May_Units_Sold
    FROM Sales.SalesOrderHeader h
    INNER JOIN Sales.SalesOrderDetail d
        ON h.SalesOrderID = d.SalesOrderID
    INNER JOIN Production.Product p
        ON d.ProductID = p.ProductID
    INNER JOIN Production.ProductSubcategory ps
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE
        h.OrderDate >= '2014-05-01'
        AND h.OrderDate < '2014-06-01'
        AND h.OnlineOrderFlag = 1
        AND pc.Name = 'Bikes'
    GROUP BY d.ProductID
),
JuneBicycleSales AS
(
    SELECT
        d.ProductID,
        SUM(d.OrderQty) AS June_Units_Sold
    FROM Sales.SalesOrderHeader h
    INNER JOIN Sales.SalesOrderDetail d
        ON h.SalesOrderID = d.SalesOrderID
    WHERE
        h.OrderDate >= '2014-06-01'
        AND h.OrderDate < '2014-07-01'
        AND h.OnlineOrderFlag = 1
    GROUP BY d.ProductID
)
SELECT
    p.ProductID,
    p.Name AS Product_Name,
    m.May_Units_Sold,
    COALESCE(j.June_Units_Sold, 0) AS June_Units_Sold,
    SUM(pi.Quantity) AS Recorded_Inventory_Quantity
FROM MayBicycleSales m
INNER JOIN Production.Product p
    ON m.ProductID = p.ProductID
LEFT JOIN JuneBicycleSales j
    ON m.ProductID = j.ProductID
LEFT JOIN Production.ProductInventory pi
    ON p.ProductID = pi.ProductID
GROUP BY
    p.ProductID,
    p.Name,
    m.May_Units_Sold,
    j.June_Units_Sold
ORDER BY
    Recorded_Inventory_Quantity DESC;


-- Business question: Did bicycle sales stop abruptly in June 2014, and was this pattern present in both sales channels?

SELECT
    YEAR(h.OrderDate) AS Sales_Year,
    MONTH(h.OrderDate) AS Sales_Month,

    CASE
        WHEN h.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Bicycle_Units_Sold,

    SUM(d.LineTotal) AS Bicycle_Revenue,

    MAX(h.OrderDate) AS Last_Bicycle_Order_Date

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

INNER JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

INNER JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

WHERE
    pc.Name = 'Bikes'
    AND h.OrderDate >= '2014-01-01'
    AND h.OrderDate < '2014-07-01'

GROUP BY
    YEAR(h.OrderDate),
    MONTH(h.OrderDate),
    h.OnlineOrderFlag

ORDER BY
    Sales_Year,
    Sales_Month,
    h.OnlineOrderFlag;


--- Investigate daily non-online bicycle sales in May

SELECT
    CAST(h.OrderDate AS DATE) AS Order_Date,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Bicycle_Units_Sold,

    SUM(d.LineTotal) AS Bicycle_Revenue

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

INNER JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

INNER JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

WHERE
    pc.Name = 'Bikes'
    AND h.OnlineOrderFlag = 0
    AND h.OrderDate >= '2014-05-01'
    AND h.OrderDate < '2014-06-01'

GROUP BY
    CAST(h.OrderDate AS DATE)

ORDER BY
    Order_Date;


--- Objective 2 : Profitability Analysis 

--- Business Question 7: What was the estimated gross profit generated during the reporting period?

SELECT
    MIN(h.OrderDate) AS First_Order_Date,
    MAX(h.OrderDate) AS Last_Order_Date,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Total_Units_Sold,

    CAST(
        SUM(d.LineTotal)
        AS DECIMAL(18,2)
    ) AS Total_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID;



-- Business Question 8: What is the estimated gross profit margin?


SELECT
    CAST(SUM(d.LineTotal) AS DECIMAL(18,2))
        AS Total_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit,

    CAST(
        (
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(d.LineTotal), 0) * 100
        AS DECIMAL(10,2)
    ) AS Estimated_Gross_Margin_Percentage

FROM Sales.SalesOrderDetail d
INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID;


-- Business Question 9 : Which products and product categories generate the highest estimated gross profit?

SELECT
    pc.Name AS Product_Category,

    COUNT(DISTINCT d.ProductID) AS Products_Sold,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.LineTotal)
        AS DECIMAL(18,2)
    ) AS Total_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit,

    CAST(
        (
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(d.LineTotal), 0) * 100
        AS DECIMAL(10,2)
    ) AS Estimated_Gross_Margin

FROM Sales.SalesOrderDetail d

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

INNER JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

INNER JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    pc.Name

ORDER BY
    Estimated_Gross_Profit DESC;



--- Business Question 10: Which products generate high revenue but low gross profit margins?

SELECT TOP 20
    p.ProductID,
    p.Name AS Product_Name,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.LineTotal)
        AS DECIMAL(18,2)
    ) AS Total_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit,

    CAST(
        (
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(d.LineTotal), 0) * 100
        AS DECIMAL(10,2)
    ) AS Estimated_Gross_Margin

FROM Sales.SalesOrderDetail d

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

GROUP BY
    p.ProductID,
    p.Name

ORDER BY
    Total_Revenue DESC;



-- identify all products with estimated gross margins below the overall business benchmark of 8.53%.
WITH Product_Profitability AS
(
    SELECT
        p.ProductID,
        p.Name AS Product_Name,

        SUM(d.OrderQty) AS Units_Sold,

        CAST(
            SUM(d.LineTotal)
            AS DECIMAL(18,2)
        ) AS Total_Revenue,

        CAST(
            SUM(d.OrderQty * p.StandardCost)
            AS DECIMAL(18,2)
        ) AS Estimated_COGS,

        CAST(
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
            AS DECIMAL(18,2)
        ) AS Estimated_Gross_Profit,

        CAST(
            (
                SUM(d.LineTotal) -
                SUM(d.OrderQty * p.StandardCost)
            ) / NULLIF(SUM(d.LineTotal), 0) * 100
            AS DECIMAL(10,2)
        ) AS Estimated_Gross_Margin

    FROM Sales.SalesOrderDetail d

    INNER JOIN Production.Product p
        ON d.ProductID = p.ProductID

    GROUP BY
        p.ProductID,
        p.Name
)

SELECT *
FROM Product_Profitability

WHERE Estimated_Gross_Margin < 8.53

ORDER BY Total_Revenue DESC;



--- Business Question 11: How does estimated gross profit and gross margin change over time?

SELECT
    YEAR(h.OrderDate) AS Sales_Year,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.LineTotal)
        AS DECIMAL(18,2)
    ) AS Total_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit,

    CAST(
        (
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(d.LineTotal), 0) * 100
        AS DECIMAL(10,2)
    ) AS Estimated_Gross_Margin

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

GROUP BY
    YEAR(h.OrderDate)

ORDER BY
    Sales_Year;



-- Like-for-like comparison

SELECT
    YEAR(h.OrderDate) AS Sales_Year,

    COUNT(DISTINCT h.SalesOrderID) AS Total_Orders,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.LineTotal)
        AS DECIMAL(18,2)
    ) AS Total_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit,

    CAST(
        (
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(d.LineTotal), 0) * 100
        AS DECIMAL(10,2)
    ) AS Estimated_Gross_Margin

FROM Sales.SalesOrderHeader h

INNER JOIN Sales.SalesOrderDetail d
    ON h.SalesOrderID = d.SalesOrderID

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

WHERE
    h.OrderDate >= '2013-01-01'
    AND h.OrderDate < '2014-07-01'
    AND MONTH(h.OrderDate) BETWEEN 1 AND 6

GROUP BY
    YEAR(h.OrderDate)

ORDER BY
    Sales_Year;


--- Business Question 12: How do discounts affect revenue and estimated gross profitability?

SELECT
    CASE
        WHEN d.UnitPriceDiscount = 0
            THEN 'No Discount'
        WHEN d.UnitPriceDiscount <= 0.10
            THEN '0.01% - 10%'
        WHEN d.UnitPriceDiscount <= 0.20
            THEN '10.01% - 20%'
        WHEN d.UnitPriceDiscount <= 0.30
            THEN '20.01% - 30%'
        ELSE 'Above 30%'
    END AS Discount_Band,

    COUNT(*) AS Order_Lines,

    SUM(d.OrderQty) AS Units_Sold,

    CAST(
        SUM(d.UnitPrice * d.OrderQty * d.UnitPriceDiscount)
        AS DECIMAL(18,2)
    ) AS Estimated_Discount_Value,

    CAST(
        SUM(d.LineTotal)
        AS DECIMAL(18,2)
    ) AS Net_Revenue,

    CAST(
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_COGS,

    CAST(
        SUM(d.LineTotal) -
        SUM(d.OrderQty * p.StandardCost)
        AS DECIMAL(18,2)
    ) AS Estimated_Gross_Profit,

    CAST(
        (
            SUM(d.LineTotal) -
            SUM(d.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(d.LineTotal), 0) * 100
        AS DECIMAL(10,2)
    ) AS Estimated_Gross_Margin

FROM Sales.SalesOrderDetail d

INNER JOIN Production.Product p
    ON d.ProductID = p.ProductID

GROUP BY
    CASE
        WHEN d.UnitPriceDiscount = 0
            THEN 'No Discount'
        WHEN d.UnitPriceDiscount <= 0.10
            THEN '0.01% - 10%'
        WHEN d.UnitPriceDiscount <= 0.20
            THEN '10.01% - 20%'
        WHEN d.UnitPriceDiscount <= 0.30
            THEN '20.01% - 30%'
        ELSE 'Above 30%'
    END

ORDER BY
    MIN(d.UnitPriceDiscount);


-- Are discounts reducing margins on the same products?

WITH Product_Discount_Analysis AS
(
    SELECT
        p.ProductID,
        p.Name AS Product_Name,

        SUM(CASE
            WHEN d.UnitPriceDiscount = 0
            THEN d.LineTotal ELSE 0
        END) AS No_Discount_Revenue,

        SUM(CASE
            WHEN d.UnitPriceDiscount = 0
            THEN d.OrderQty * p.StandardCost ELSE 0
        END) AS No_Discount_COGS,

        SUM(CASE
            WHEN d.UnitPriceDiscount > 0
            THEN d.LineTotal ELSE 0
        END) AS Discounted_Revenue,

        SUM(CASE
            WHEN d.UnitPriceDiscount > 0
            THEN d.OrderQty * p.StandardCost ELSE 0
        END) AS Discounted_COGS,

        SUM(CASE
            WHEN d.UnitPriceDiscount > 0
            THEN d.OrderQty ELSE 0
        END) AS Discounted_Units,

        SUM(CASE
            WHEN d.UnitPriceDiscount > 0
            THEN d.UnitPrice * d.OrderQty * d.UnitPriceDiscount
            ELSE 0
        END) AS Discount_Value

    FROM Sales.SalesOrderDetail d

    INNER JOIN Production.Product p
        ON d.ProductID = p.ProductID

    GROUP BY
        p.ProductID,
        p.Name
)

SELECT
    ProductID,
    Product_Name,

    CAST(No_Discount_Revenue AS DECIMAL(18,2))
        AS No_Discount_Revenue,

    CAST(
        (No_Discount_Revenue - No_Discount_COGS)
        / NULLIF(No_Discount_Revenue, 0) * 100
        AS DECIMAL(10,2)
    ) AS No_Discount_Margin,

    CAST(Discounted_Revenue AS DECIMAL(18,2))
        AS Discounted_Revenue,

    Discounted_Units,

    CAST(Discount_Value AS DECIMAL(18,2))
        AS Discount_Value,

    CAST(
        Discounted_Revenue - Discounted_COGS
        AS DECIMAL(18,2)
    ) AS Discounted_Gross_Profit,

    CAST(
        (Discounted_Revenue - Discounted_COGS)
        / NULLIF(Discounted_Revenue, 0) * 100
        AS DECIMAL(10,2)
    ) AS Discounted_Gross_Margin

FROM Product_Discount_Analysis

WHERE
    No_Discount_Revenue > 0
    AND Discounted_Revenue > 0

ORDER BY
    Discount_Value DESC;


--- Product Performance Analysis

-- Business question 13: Which products generate the highest revenue?

SELECT TOP 20
    p.ProductID,
    p.Name AS Product_Name,
    pc.Name AS Product_Category,
    SUM(sod.OrderQty) AS Units_Sold,
    SUM(sod.LineTotal) AS Total_Revenue,
    SUM(sod.OrderQty * p.StandardCost) AS Estimated_COGS,
    SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost) AS Estimated_Gross_Profit,
    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(sod.LineTotal), 0) * 100,
        2
    ) AS Estimated_Gross_Margin_Percent

FROM Production.Product p

INNER JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    p.ProductID,
    p.Name,
    pc.Name

ORDER BY
    Total_Revenue DESC;



-- Business question 14 : Which products sell the highest number of units?

SELECT TOP 20
    p.ProductID,
    p.Name AS Product_Name,
    pc.Name AS Product_Category,
    SUM(sod.OrderQty) AS Units_Sold,
    SUM(sod.LineTotal) AS Total_Revenue

FROM Production.Product p

INNER JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    p.ProductID,
    p.Name,
    pc.Name

ORDER BY
    Units_Sold DESC;


--- Business question 15: What is the revenue contribution of each product category?

SELECT
    pc.Name AS Product_Category,
    COUNT(DISTINCT p.ProductID) AS Products_Sold,
    SUM(sod.OrderQty) AS Total_Units_Sold,
    SUM(sod.LineTotal) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Production.Product p

INNER JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    pc.Name

ORDER BY
    Total_Revenue DESC;

--- Business Question 16: Which products are underperforming?

SELECT
    p.ProductID,
    p.Name AS Product_Name,
    pc.Name AS Product_Category,
    SUM(sod.OrderQty) AS Units_Sold,
    SUM(sod.LineTotal) AS Total_Revenue,
    SUM(sod.OrderQty * p.StandardCost) AS Estimated_COGS,

    SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost)
        AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(sod.LineTotal), 0) * 100,
        2
    ) AS Estimated_Gross_Margin_Percent

FROM Production.Product p

INNER JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    p.ProductID,
    p.Name,
    pc.Name

ORDER BY
    Total_Revenue ASC;


    --- Identify all loss-making products
    SELECT
    p.ProductID,
    p.Name AS Product_Name,
    pc.Name AS Product_Category,
    SUM(sod.OrderQty) AS Units_Sold,
    SUM(sod.LineTotal) AS Total_Revenue,

    SUM(sod.OrderQty * p.StandardCost)
        AS Estimated_COGS,

    SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost)
        AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(sod.LineTotal), 0) * 100,
        2
    ) AS Estimated_Gross_Margin_Percent

FROM Production.Product p

INNER JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    p.ProductID,
    p.Name,
    pc.Name

HAVING
    SUM(sod.LineTotal) -
    SUM(sod.OrderQty * p.StandardCost) < 0

ORDER BY
    Estimated_Gross_Profit ASC;


--- Business question 17: How do product categories and subcategories perform in terms of sales revenue, units sold and estimated profitability?


SELECT
    pc.Name AS Product_Category,
    ps.Name AS Product_Subcategory,

    COUNT(DISTINCT p.ProductID) AS Products_Sold,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(
        SUM(sod.LineTotal), 2
    ) AS Total_Revenue,

    ROUND(
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_COGS,

    ROUND(
        SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) / NULLIF(SUM(sod.LineTotal), 0) * 100,
        2
    ) AS Estimated_Gross_Margin_Percent,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Production.Product p

INNER JOIN Sales.SalesOrderDetail sod
    ON p.ProductID = sod.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    pc.Name,
    ps.Name

ORDER BY
    Total_Revenue DESC;


--- Customer Analysis

-- Business question 18: How many unique customers purchased from AdventureWorks during the study period?

    
SELECT
    COUNT(DISTINCT CustomerID) AS Unique_Customers
FROM Sales.SalesOrderHeader;


SELECT
    COUNT(*) AS Total_Registered_Customers
FROM Sales.Customer;


--- Business question 19: Who are the top 10 customers by revenue?


SELECT TOP 10
    c.CustomerID,
    c.AccountNumber,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Purchased,

    ROUND(
        SUM(sod.LineTotal), 2
    ) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) /
        COUNT(DISTINCT soh.SalesOrderID), 2
    ) AS Average_Order_Value

FROM Sales.Customer c

INNER JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

GROUP BY
    c.CustomerID,
    c.AccountNumber

ORDER BY
    Total_Revenue DESC;


--- Business question 20: How does revenue differ between individual customers and business customers?


SELECT
    CASE
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        WHEN c.StoreID IS NOT NULL THEN 'Business'
        ELSE 'Unclassified'
    END AS Customer_Type,

    COUNT(DISTINCT c.CustomerID) AS Unique_Customers,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Purchased,

    ROUND(
        SUM(sod.LineTotal), 2
    ) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) /
        COUNT(DISTINCT soh.SalesOrderID), 2
    ) AS Average_Order_Value

FROM Sales.Customer c

INNER JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

GROUP BY
    CASE
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        WHEN c.StoreID IS NOT NULL THEN 'Business'
        ELSE 'Unclassified'
    END

ORDER BY
    Total_Revenue DESC;


 -- customer classification 

SELECT
    CASE
        WHEN PersonID IS NOT NULL
             AND StoreID IS NULL
            THEN 'Individual'

        WHEN StoreID IS NOT NULL
             AND PersonID IS NULL
            THEN 'Business'

        WHEN PersonID IS NOT NULL
             AND StoreID IS NOT NULL
            THEN 'Both'

        ELSE 'Unclassified'
    END AS Customer_Type,

    COUNT(*) AS Total_Customers

FROM Sales.Customer

GROUP BY
    CASE
        WHEN PersonID IS NOT NULL
             AND StoreID IS NULL
            THEN 'Individual'

        WHEN StoreID IS NOT NULL
             AND PersonID IS NULL
            THEN 'Business'

        WHEN PersonID IS NOT NULL
             AND StoreID IS NOT NULL
            THEN 'Both'

        ELSE 'Unclassified'
    END

ORDER BY
    Total_Customers DESC;

--- rerun question 20


SELECT
    CASE
        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NULL
            THEN 'Individual'

        WHEN c.StoreID IS NOT NULL
             AND c.PersonID IS NULL
            THEN 'Business'

        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NOT NULL
            THEN 'Both'

        ELSE 'Unclassified'
    END AS Customer_Type,

    COUNT(DISTINCT c.CustomerID)
        AS Registered_Customers,

    COUNT(DISTINCT
        CASE
            WHEN soh.SalesOrderID IS NOT NULL
            THEN c.CustomerID
        END
    ) AS Purchasing_Customers,

    COUNT(DISTINCT soh.SalesOrderID)
        AS Total_Orders,

    COALESCE(SUM(sod.OrderQty), 0)
        AS Units_Purchased,

    ROUND(
        COALESCE(SUM(sod.LineTotal), 0), 2
    ) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) /
        NULLIF(COUNT(DISTINCT soh.SalesOrderID), 0),
        2
    ) AS Average_Order_Value

FROM Sales.Customer c

LEFT JOIN Sales.SalesOrderHeader soh
    ON c.CustomerID = soh.CustomerID

LEFT JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

GROUP BY
    CASE
        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NULL
            THEN 'Individual'

        WHEN c.StoreID IS NOT NULL
             AND c.PersonID IS NULL
            THEN 'Business'

        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NOT NULL
            THEN 'Both'

        ELSE 'Unclassified'
    END

ORDER BY
    Total_Revenue DESC;



--- Business question 21: How frequently do customers purchase from AdventureWorks?


WITH Customer_Order_Count AS
(
    SELECT
        CustomerID,
        COUNT(DISTINCT SalesOrderID) AS Total_Orders
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
)

SELECT
    CASE
        WHEN Total_Orders = 1 THEN 'One-time Customer'
        WHEN Total_Orders BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN Total_Orders BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'Frequent Customer'
    END AS Purchase_Frequency,

    COUNT(*) AS Number_of_Customers,

    SUM(Total_Orders) AS Total_Orders

FROM Customer_Order_Count

GROUP BY
    CASE
        WHEN Total_Orders = 1 THEN 'One-time Customer'
        WHEN Total_Orders BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN Total_Orders BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'Frequent Customer'
    END

ORDER BY
    MIN(Total_Orders);



--- Business Question 22: How much revenue is generated by repeat customers compared with one-time customers?


WITH Customer_Purchase AS
(
    SELECT
        soh.CustomerID,
        COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,
        SUM(sod.LineTotal) AS Total_Revenue
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY soh.CustomerID
)

SELECT
    CASE
        WHEN Total_Orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS Customer_Type,

    COUNT(*) AS Number_of_Customers,

    SUM(Total_Orders) AS Total_Orders,

    ROUND(SUM(Total_Revenue), 2) AS Total_Revenue,

    ROUND(
        SUM(Total_Revenue) * 100.0 /
        SUM(SUM(Total_Revenue)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Customer_Purchase

GROUP BY
    CASE
        WHEN Total_Orders = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END

ORDER BY Total_Revenue DESC;



--- Business Question 23: To what extent does AdventureWorks depend on a small number of high-value customers for its total revenue?

WITH Customer_Revenue AS
(
    SELECT
        soh.CustomerID,
        SUM(sod.LineTotal) AS Total_Revenue
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY soh.CustomerID
),

Ranked_Customers AS
(
    SELECT
        CustomerID,
        Total_Revenue,
        ROW_NUMBER() OVER (
            ORDER BY Total_Revenue DESC
        ) AS Revenue_Rank
    FROM Customer_Revenue
)

SELECT
    CASE
        WHEN Revenue_Rank <= 10 THEN 'Top 10 Customers'
        WHEN Revenue_Rank <= 50 THEN 'Top 50 Customers'
        WHEN Revenue_Rank <= 100 THEN 'Top 100 Customers'
        ELSE 'Remaining Customers'
    END AS Customer_Group,

    COUNT(*) AS Number_of_Customers,

    ROUND(SUM(Total_Revenue), 2) AS Total_Revenue,

    ROUND(
        SUM(Total_Revenue) * 100.0 /
        SUM(SUM(Total_Revenue)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Ranked_Customers

GROUP BY
    CASE
        WHEN Revenue_Rank <= 10 THEN 'Top 10 Customers'
        WHEN Revenue_Rank <= 50 THEN 'Top 50 Customers'
        WHEN Revenue_Rank <= 100 THEN 'Top 100 Customers'
        ELSE 'Remaining Customers'
    END

ORDER BY
    MIN(Revenue_Rank);


--- Geographical performance

--- Business question 24: Which geographical territories generate the highest sales revenue for AdventureWorks?

SELECT
    st.Name AS Sales_Territory,
    st.CountryRegionCode,
    st.[Group] AS Geographic_Region,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    COUNT(DISTINCT soh.CustomerID) AS Unique_Customers,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID

GROUP BY
    st.Name,
    st.CountryRegionCode,
    st.[Group]

ORDER BY
    Total_Revenue DESC;



--- business question 25: Which geographical territories generate the highest estimated gross profit, and which have weaker profitability?

SELECT
    st.Name AS Sales_Territory,
    st.CountryRegionCode,
    st.[Group] AS Geographic_Region,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_COGS,

    ROUND(
        SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) * 100.0 /
        NULLIF(SUM(sod.LineTotal), 0),
        2
    ) AS Estimated_Gross_Margin_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID

GROUP BY
    st.Name,
    st.CountryRegionCode,
    st.[Group]

ORDER BY
    Estimated_Gross_Profit DESC;

--Business question 26 : Which geographical markets demonstrate the strongest sales growth over time?

WITH Territory_Annual_Sales AS
(
    SELECT
        st.Name AS Sales_Territory,

        YEAR(soh.OrderDate) AS Sales_Year,

        SUM(sod.LineTotal) AS Total_Revenue

    FROM Sales.SalesOrderHeader soh

    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID

    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID

    GROUP BY
        st.Name,
        YEAR(soh.OrderDate)
),

Territory_Growth AS
(
    SELECT
        Sales_Territory,
        Sales_Year,
        Total_Revenue,

        LAG(Total_Revenue) OVER (
            PARTITION BY Sales_Territory
            ORDER BY Sales_Year
        ) AS Previous_Year_Revenue

    FROM Territory_Annual_Sales
)

SELECT
    Sales_Territory,
    Sales_Year,

    ROUND(Total_Revenue, 2) AS Total_Revenue,

    ROUND(Previous_Year_Revenue, 2) AS Previous_Year_Revenue,

    ROUND(
        (Total_Revenue - Previous_Year_Revenue)
        * 100.0 /
        NULLIF(Previous_Year_Revenue, 0),
        2
    ) AS Revenue_Growth_Percent

FROM Territory_Growth

ORDER BY
    Sales_Territory,
    Sales_Year;



--= Like-for-like geographical growth

SELECT
    st.Name AS Sales_Territory,

    YEAR(soh.OrderDate) AS Sales_Year,

    SUM(sod.LineTotal) AS Total_Revenue

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID

WHERE
    (
        soh.OrderDate >= '2013-01-01'
        AND soh.OrderDate < '2013-07-01'
    )
    OR
    (
        soh.OrderDate >= '2014-01-01'
        AND soh.OrderDate < '2014-07-01'
    )

GROUP BY
    st.Name,
    YEAR(soh.OrderDate)

ORDER BY
    st.Name,
    Sales_Year;


--- Business question 27: Which product categories generate the highest revenue in each geographical territory?

SELECT
    st.Name AS Sales_Territory,

    pc.Name AS Product_Category,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (
            PARTITION BY st.Name
        ),
        2
    ) AS Territory_Revenue_Contribution_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

INNER JOIN Production.ProductSubcategory psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID

INNER JOIN Production.ProductCategory pc
    ON psc.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    st.Name,
    pc.Name

ORDER BY
    st.Name,
    Total_Revenue DESC;



--- Business question 28: Which geographical markets are underperforming?

WITH Territory_Performance AS
(
    SELECT
        st.Name AS Sales_Territory,

        SUM(sod.LineTotal) AS Total_Revenue,

        SUM(sod.OrderQty * p.StandardCost) AS Estimated_COGS,

        SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost)
            AS Estimated_Gross_Profit,

        COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders

    FROM Sales.SalesOrderHeader soh

    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID

    INNER JOIN Production.Product p
        ON sod.ProductID = p.ProductID

    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID

    GROUP BY st.Name
),

Territory_Growth AS
(
    SELECT
        st.Name AS Sales_Territory,

        SUM(
            CASE
                WHEN soh.OrderDate >= '2013-01-01'
                 AND soh.OrderDate < '2013-07-01'
                THEN sod.LineTotal ELSE 0
            END
        ) AS Revenue_2013_H1,

        SUM(
            CASE
                WHEN soh.OrderDate >= '2014-01-01'
                 AND soh.OrderDate < '2014-07-01'
                THEN sod.LineTotal ELSE 0
            END
        ) AS Revenue_2014_H1

    FROM Sales.SalesOrderHeader soh

    INNER JOIN Sales.SalesOrderDetail sod
        ON soh.SalesOrderID = sod.SalesOrderID

    INNER JOIN Sales.SalesTerritory st
        ON soh.TerritoryID = st.TerritoryID

    GROUP BY st.Name
)

SELECT
    tp.Sales_Territory,

    ROUND(tp.Total_Revenue, 2) AS Total_Revenue,

    ROUND(
        tp.Total_Revenue * 100.0 /
        SUM(tp.Total_Revenue) OVER (),
        2
    ) AS Revenue_Contribution_Percent,

    ROUND(tp.Estimated_Gross_Profit, 2)
        AS Estimated_Gross_Profit,

    ROUND(
        tp.Estimated_Gross_Profit * 100.0 /
        NULLIF(tp.Total_Revenue, 0),
        2
    ) AS Estimated_Gross_Margin_Percent,

    ROUND(tg.Revenue_2013_H1, 2) AS Revenue_2013_H1,

    ROUND(tg.Revenue_2014_H1, 2) AS Revenue_2014_H1,

    ROUND(
        (tg.Revenue_2014_H1 - tg.Revenue_2013_H1)
        * 100.0 /
        NULLIF(tg.Revenue_2013_H1, 0),
        2
    ) AS Revenue_Growth_Percent

FROM Territory_Performance tp

INNER JOIN Territory_Growth tg
    ON tp.Sales_Territory = tg.Sales_Territory

ORDER BY
    Estimated_Gross_Margin_Percent ASC;


-- Sales channel analysis

--- Business question 29: How much revenue is generated through online versus non-online channels?

SELECT
    CASE
        WHEN OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    COUNT(DISTINCT soh.CustomerID) AS Unique_Customers,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

GROUP BY
    OnlineOrderFlag

ORDER BY
    Total_Revenue DESC;



-- Business question 30 : How many orders are generated through each sales channel?

SELECT
    CASE
        WHEN OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(SalesOrderID) AS Total_Orders,

    ROUND(
        COUNT(SalesOrderID) * 100.0 /
        SUM(COUNT(SalesOrderID)) OVER (),
        2
    ) AS Order_Contribution_Percent

FROM Sales.SalesOrderHeader

GROUP BY OnlineOrderFlag

ORDER BY Total_Orders DESC;

--- Business question 31: What is the average order value (AOV) for each sales channel?

SELECT
    CASE
        WHEN OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(SalesOrderID) AS Total_Orders,

    ROUND(SUM(SubTotal), 2) AS Total_Revenue,

    ROUND(
        AVG(SubTotal), 2
    ) AS Average_Order_Value

FROM Sales.SalesOrderHeader

GROUP BY OnlineOrderFlag

ORDER BY Average_Order_Value DESC;

--- Business question 32: What is the estimated gross profit generated by each sales channel?

SELECT
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_COGS,

    ROUND(
        SUM(sod.LineTotal) -
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) * 100.0 /
        NULLIF(SUM(sod.LineTotal), 0),
        2
    ) AS Estimated_Gross_Margin_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

GROUP BY soh.OnlineOrderFlag

ORDER BY Estimated_Gross_Profit DESC;


-- Business question 33: How have sales trends changed over time across online and non-online channels?

SELECT
    YEAR(soh.OrderDate) AS Sales_Year,

    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (
            PARTITION BY YEAR(soh.OrderDate)
        ),
        2
    ) AS Revenue_Contribution_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

GROUP BY
    YEAR(soh.OrderDate),
    soh.OnlineOrderFlag

ORDER BY
    Sales_Year,
    Sales_Channel;




-- Geographical revenue reconciliation

SELECT
    CASE
        WHEN soh.TerritoryID IS NULL
            THEN 'Unassigned Territory'
        WHEN st.TerritoryID IS NULL
            THEN 'Unmatched Territory'
        ELSE st.Name
    END AS Sales_Territory,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    COUNT(DISTINCT soh.CustomerID) AS Unique_Customers,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Total_Revenue,

    ROUND(
        SUM(sod.LineTotal) * 100.0 /
        SUM(SUM(sod.LineTotal)) OVER (),
        2
    ) AS Revenue_Contribution_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

LEFT JOIN Sales.SalesTerritory st
    ON soh.TerritoryID = st.TerritoryID

GROUP BY
    CASE
        WHEN soh.TerritoryID IS NULL
            THEN 'Unassigned Territory'
        WHEN st.TerritoryID IS NULL
            THEN 'Unmatched Territory'
        ELSE st.Name
    END

ORDER BY Total_Revenue DESC;


--- Recalculate profitability by channel

SELECT
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    COUNT(sod.SalesOrderDetailID) AS Total_Order_Lines,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Revenue,

    ROUND(
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_COGS,

    ROUND(
        SUM(sod.LineTotal)
        - SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal)
            - SUM(sod.OrderQty * p.StandardCost)
        ) * 100.0 / NULLIF(SUM(sod.LineTotal), 0),
        2
    ) AS Estimated_Gross_Margin_Percent,

    SUM(
        CASE
            WHEN p.ProductID IS NULL THEN 1
            ELSE 0
        END
    ) AS Unmatched_Product_Lines,

    SUM(
        CASE
            WHEN p.ProductID IS NOT NULL
                 AND p.StandardCost IS NULL THEN 1
            ELSE 0
        END
    ) AS Missing_Standard_Cost_Lines

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

LEFT JOIN Production.Product p
    ON sod.ProductID = p.ProductID

GROUP BY
    soh.OnlineOrderFlag

ORDER BY Revenue DESC;




SELECT
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    pc.Name AS Product_Category,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Revenue,

    ROUND(
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_COGS,

    ROUND(
        SUM(sod.LineTotal)
        - SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal)
            - SUM(sod.OrderQty * p.StandardCost)
        ) * 100.0 / NULLIF(SUM(sod.LineTotal), 0),
        2
    ) AS Estimated_Gross_Margin_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

GROUP BY
    soh.OnlineOrderFlag,
    pc.Name

ORDER BY
    Sales_Channel,
    Revenue DESC;


-- Bike profitability by individual product and channel

SELECT
    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    p.ProductID,
    p.Name AS Product_Name,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Revenue,

    ROUND(
        SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_COGS,

    ROUND(
        SUM(sod.LineTotal)
        - SUM(sod.OrderQty * p.StandardCost), 2
    ) AS Estimated_Gross_Profit,

    ROUND(
        (
            SUM(sod.LineTotal)
            - SUM(sod.OrderQty * p.StandardCost)
        ) * 100.0 / NULLIF(SUM(sod.LineTotal), 0),
        2
    ) AS Estimated_Gross_Margin_Percent,

    ROUND(
        SUM(
            sod.UnitPrice *
            sod.UnitPriceDiscount *
            sod.OrderQty
        ), 2
    ) AS Discount_Value,

    ROUND(
        SUM(sod.LineTotal) / NULLIF(SUM(sod.OrderQty), 0),
        2
    ) AS Average_Net_Selling_Price_Per_Unit,

    ROUND(p.StandardCost, 2) AS Standard_Cost_Per_Unit

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

INNER JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

INNER JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID

WHERE pc.Name = 'Bikes'

GROUP BY
    soh.OnlineOrderFlag,
    p.ProductID,
    p.Name,
    p.StandardCost

ORDER BY
    Sales_Channel,
    Estimated_Gross_Profit ASC;


--- Did the price differences occur in the same years?

SELECT
    YEAR(soh.OrderDate) AS Sales_Year,

    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    p.ProductID,
    p.Name AS Product_Name,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,

    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Revenue,

    ROUND(
        SUM(sod.UnitPrice * sod.OrderQty), 2
    ) AS Gross_Sales_Before_Discount,

    ROUND(
        SUM(
            sod.UnitPrice *
            sod.UnitPriceDiscount *
            sod.OrderQty
        ), 2
    ) AS Discount_Value,

    ROUND(
        SUM(sod.LineTotal) /
        NULLIF(SUM(sod.OrderQty), 0), 2
    ) AS Average_Net_Selling_Price,

    ROUND(
        SUM(sod.UnitPrice * sod.OrderQty) /
        NULLIF(SUM(sod.OrderQty), 0), 2
    ) AS Average_Unit_Price_Before_Discount,

    ROUND(p.StandardCost, 2) AS Standard_Cost_Per_Unit,

    ROUND(
        (
            SUM(sod.LineTotal) -
            SUM(sod.OrderQty * p.StandardCost)
        ) * 100.0 /
        NULLIF(SUM(sod.LineTotal), 0), 2
    ) AS Estimated_Gross_Margin_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

WHERE sod.ProductID IN (
    957, 793, 954, 794, 762, 795, 976
)

GROUP BY
    YEAR(soh.OrderDate),
    soh.OnlineOrderFlag,
    p.ProductID,
    p.Name,
    p.StandardCost

ORDER BY
    p.ProductID,
    Sales_Year,
    Sales_Channel;


-- check whether the price differences are consistent across customer types.

SELECT
    CASE
        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NOT NULL THEN 'Both'
        WHEN c.StoreID IS NOT NULL THEN 'Business'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unclassified'
    END AS Customer_Type,

    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    p.ProductID,
    p.Name AS Product_Name,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,
    SUM(sod.OrderQty) AS Units_Sold,

    ROUND(SUM(sod.LineTotal), 2) AS Revenue,

    ROUND(
        SUM(sod.LineTotal) / NULLIF(SUM(sod.OrderQty), 0), 2
    ) AS Average_Net_Selling_Price,

    ROUND(p.StandardCost, 2) AS Standard_Cost_Per_Unit,

    ROUND(
        (SUM(sod.LineTotal) -
         SUM(sod.OrderQty * p.StandardCost))
        * 100.0 / NULLIF(SUM(sod.LineTotal), 0), 2
    ) AS Estimated_Gross_Margin_Percent

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

INNER JOIN Sales.Customer c
    ON soh.CustomerID = c.CustomerID

INNER JOIN Production.Product p
    ON sod.ProductID = p.ProductID

WHERE sod.ProductID IN (762, 793, 794, 795, 954, 957, 976)

GROUP BY
    CASE
        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NOT NULL THEN 'Both'
        WHEN c.StoreID IS NOT NULL THEN 'Business'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unclassified'
    END,
    soh.OnlineOrderFlag,
    p.ProductID,
    p.Name,
    p.StandardCost

ORDER BY
    p.ProductID,
    Customer_Type,
    Sales_Channel;




--- Establish whether the customer/channel relationship applies to the entire dataset or only to the seven selected products.

SELECT
    CASE
        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NOT NULL THEN 'Both'
        WHEN c.StoreID IS NOT NULL THEN 'Business'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unclassified'
    END AS Customer_Type,

    CASE
        WHEN soh.OnlineOrderFlag = 1 THEN 'Online'
        ELSE 'Non-Online'
    END AS Sales_Channel,

    COUNT(DISTINCT soh.SalesOrderID) AS Total_Orders,
    COUNT(DISTINCT soh.CustomerID) AS Total_Customers,
    SUM(sod.OrderQty) AS Units_Sold,
    ROUND(SUM(sod.LineTotal), 2) AS Revenue,

    ROUND(
        SUM(sod.LineTotal) /
        NULLIF(SUM(sod.OrderQty), 0), 2
    ) AS Average_Selling_Price_Per_Unit

FROM Sales.SalesOrderHeader soh

INNER JOIN Sales.Customer c
    ON soh.CustomerID = c.CustomerID

INNER JOIN Sales.SalesOrderDetail sod
    ON soh.SalesOrderID = sod.SalesOrderID

GROUP BY
    CASE
        WHEN c.PersonID IS NOT NULL
             AND c.StoreID IS NOT NULL THEN 'Both'
        WHEN c.StoreID IS NOT NULL THEN 'Business'
        WHEN c.PersonID IS NOT NULL THEN 'Individual'
        ELSE 'Unclassified'
    END,
    soh.OnlineOrderFlag

ORDER BY Customer_Type, Sales_Channel;











