
DECLARE @Temp TABLE
(
    [SkuShort] VARCHAR(50),
    [Country] VARCHAR(10),
    [Year] int,
    [Week] int,
    [NumberWorkdays] int,
    [AvgTemp] float,
    [AvgRain] float,
    [AvgSun] float,
    [IsLockdown] bit,
    [PdtHl] float,
    [BgtHl] float,
    [SalesHl] float
)


INSERT INTO @Temp
    ([SkuShort], [Country], [Year], [Week], [NumberWorkdays], [AvgTemp], [AvgRain], [AvgSun], [IsLockdown], [PdtHl], [BgtHl], [SalesHl])
SELECT --t.*
    t.SHORT_SKU
    , t.[Country]
    , CAST(t.[Year] AS int)
    , CAST(t.[Week] AS int)
    , CAST(t.[Workdays] AS int)
    , AVG(t.[AvgTemp]) AS TEMP
    , AVG(t.[AvgRain]) AS RAIN
    , AVG(t.[AvgSun]) AS SUN
    , t.IsLockdown
    , SUM([PDT_HL])
    , SUM([BGT_HL])
    , SUM(t.[SalesHl]) AS RESULT

FROM (SELECT [Country]
      , [Calweek]
      , [Year]
      , [Week]
      , [Workdays]
      , [GT_SKU]
      , [DP_SKU]
      , SUBSTRING([DP_SKU], 1, 5) AS 'SHORT_SKU'
      , [Description]
      , [Brand]
      , [SubBrand]
      , [ProductGroup]
      , [PrimaryPack]
      , [Sales_HL] 
      , CASE WHEN [Sales_HL] > 0 THEN [Sales_HL]   
        ELSE 0  
        END AS 'SalesHl'
      , [PDT_HL]
      , [BGT_HL]
      , [AvgTemp]
      , [AvgRain]
      , [AvgSun]
      , CASE 
        WHEN [Country] = 'CZ' AND [Year] = 2020 AND [Week] BETWEEN 12 AND 21 THEN 1
        WHEN [Country] = 'CZ' AND [Year] = 2020 AND [Week] BETWEEN 42 AND 53  THEN 1
        WHEN [Country] = 'CZ' AND [Year] = 2021 THEN 1

        --WHEN [Country] = 'SK' AND [Year] = 2020 AND [Week] BETWEEN 12 AND 21 THEN 1
        --WHEN [Country] = 'SK' AND [Year] = 2020 AND [Week] BETWEEN 42 AND 53  THEN 1
        --WHEN [Country] = 'SK' AND [Year] = 2021 THEN 1
        ELSE 0  
        END AS 'IsLockdown'
    FROM [FC_Tool].[dbo].[ML_Table]
  ) AS t
WHERE SHORT_SKU = '02605'
    AND [Country] = 'CZ'
    --AND [Year] < 2021
GROUP BY [Country], t.[Year], t.[Week], t.[Workdays], SHORT_SKU, IsLockdown


--SELECT * FROM @Temp


SELECT
    [SkuShort]
    , [Country]
    , [Year] 
    , [Week]
    , [NumberWorkdays]
    , [AvgTemp]
    , [AvgRain]
    , [AvgSun]
    , [IsLockdown]
    , [PdtHl]
    , [BgtHl]
    , (SELECT TOP(1)
        SalesHl
    FROM @Temp AS w1
    WHERE w1.[Year] = CASE WHEN  (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1  END
        AND w1.[Week] = CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52  END 
        ) AS PrevWeekSalesHl1
    , (SELECT TOP(1)
        SalesHl
    FROM @Temp AS w1
    WHERE w1.[Year] = CASE WHEN  (t.Week - 2) > 0 THEN t.[Year] ELSE t.[Year] - 1  END
        AND w1.[Week] = CASE 
        WHEN (t.Week - 2) > 0 THEN (t.Week -2) 
        WHEN (t.Week - 2) = 0 THEN 52 
        ELSE 51  END 
        ) AS PrevWeekSalesHl2
    , SalesHl

FROM @Temp AS t
--WHERE [Year] NOT IN (2018, 2021)
ORDER BY  [Country], [Year], [Week]