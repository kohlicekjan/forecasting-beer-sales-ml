
DECLARE @Temp TABLE
(
    [SkuShort] VARCHAR(50),
    [ProductGroup] VARCHAR(50),
    [PrimaryPack] VARCHAR(50),
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
    [OldPredSalesHl] float,
    [SalesHl] float
)


INSERT INTO @Temp
    ([SkuShort], [ProductGroup], [PrimaryPack], [Country], [Year], [Week], [NumberWorkdays], [AvgTemp], [AvgRain], [AvgSun], [IsLockdown], [PdtHl], [BgtHl], [OldPredSalesHl], [SalesHl])
SELECT --t.*
    t.SHORT_SKU
    , t.[ProductGroup]
    , t.[PrimaryPack]
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
    , SUM([LF1_HL]) 
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
      , [LF1_HL]
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
    WHERE 
        [Country] = 'CZ'
        AND [DP_SKU] IS NOT NULL
        AND [PrimaryPack] IS NOT NULL
        AND [Sales_HL] IS NOT NULL
        AND [AvgTemp] IS NOT NULL
        AND [AvgRain] IS NOT NULL
        AND [AvgSun] IS NOT NULL
        AND [PrimaryPack] IN ('KEG WOODEN', 'KEG', 'KEG ONE WAY', 'TANK') --ON-TRADE
        --AND [PrimaryPack] IN ('NRB', 'CAN', 'RB', 'PET') --OFF-TRADE
  ) AS t
--WHERE  
    
    --AND SHORT_SKU IN ('06892') --'11276','02605', '02115', '06892'
    --AND [Year] < 2021
GROUP BY t.[Country], t.[Year], t.[Week], t.[Workdays], t.SHORT_SKU, t.IsLockdown, t.[ProductGroup], t.[PrimaryPack]


--SELECT * FROM @Temp

-- SELECT
--     t.[SkuShort]
--     , t.[Country]
--     , t.[Year] 
--     , t.[Week]
--     , t.[NumberWorkdays]
--     , t.[AvgTemp]
--     , t.[AvgRain]
--     , t.[AvgSun]
--     , t.[IsLockdown]
--     , t.[PdtHl]
--     , w1.PdtHl AS PrevWeekPdtHl1
--     , t.[BgtHl]
--     , w1.[BgtHl] AS PrevWeekBgtHl1
--     , t.SalesHl
--     , w1.SalesHl AS PrevWeekSalesHl1
--     , w2.SalesHl AS PrevWeekSalesHl2
-- FROM @Temp AS t
--     LEFT JOIN @Temp AS w1 ON 
--         w1.SkuShort = t.SkuShort
--         AND w1.[Year] = CASE WHEN (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1 END
--         AND w1.[Week] = CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52 END 
--     LEFT JOIN @Temp AS w2 ON  
--         w2.SkuShort = t.SkuShort
--         AND w2.[Year] = CASE WHEN (t.Week - 2) > 0 THEN t.[Year] ELSE t.[Year] - 1 END
--         AND w2.[Week] = CASE WHEN (t.Week - 2) > 0 THEN (t.Week -2) 
--                             WHEN (t.Week - 2) = 0 THEN 52 
--                             ELSE 51  END 
-- --WHERE [Year] NOT IN (2018, 2021)
-- ORDER BY  t.[Country], t.[Year], t.[Week]


SELECT
    [SkuShort]
    , [ProductGroup]
    , [PrimaryPack]
    , [Country]
    , [Year] 
    , [Week]
    , [NumberWorkdays]
    , [AvgTemp]
    , [AvgRain]
    , [AvgSun]
    , [IsLockdown]
    , [PdtHl]
    , (SELECT TOP(1)
        [PdtHl]
    FROM @Temp AS w1
    WHERE w1.SkuShort = t.SkuShort
        AND w1.[Year] = CASE WHEN (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1 END
        AND w1.[Week] = CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52  END 
        ) AS PrevWeekPdtHl1
    , [BgtHl]
    , (SELECT TOP(1)
        [BgtHl]
    FROM @Temp AS w1
    WHERE w1.SkuShort = t.SkuShort
        AND w1.[Year] = CASE WHEN (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1 END
        AND w1.[Week] = CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52  END 
        ) AS PrevWeekBgtHl1    
    , SalesHl
    , (SELECT TOP(1)
        SalesHl
    FROM @Temp AS w1
    WHERE w1.SkuShort = t.SkuShort
        AND w1.[Year] = CASE WHEN (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1 END
        AND w1.[Week] = CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52  END 
        ) AS PrevWeekSalesHl1
    , (SELECT TOP(1)
        SalesHl
    FROM @Temp AS w1
    WHERE w1.SkuShort = t.SkuShort
        AND w1.[Year] = CASE WHEN (t.Week - 2) > 0 THEN t.[Year] ELSE t.[Year] - 1 END
        AND w1.[Week] = CASE WHEN (t.Week - 2) > 0 THEN (t.Week -2) 
                            WHEN (t.Week - 2) = 0 THEN 52 
                            ELSE 51  END 
        ) AS PrevWeekSalesHl2
    , [OldPredSalesHl]
FROM @Temp AS t
--WHERE [Year] NOT IN (2018, 2021)
ORDER BY  [Country], [Year], [Week]