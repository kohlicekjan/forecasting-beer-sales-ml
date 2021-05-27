
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

FROM (SELECT mlt.[Country]
      , mlt.[Calweek]
      , mlt.[Year]
      , mlt.[Week]
      , mlt.[Workdays]
      , mlt.[GT_SKU]
      , mlt.[DP_SKU]
      , SUBSTRING(mlt.[DP_SKU], 1, 5) AS 'SHORT_SKU'
      , mlt.[Description]
      , mlt.[Brand]
      , mlt.[SubBrand]
      , mlt.[ProductGroup]
      , mlt.[PrimaryPack]
      , mlt.[LF1_HL]
      , mlt.[Sales_HL] 
      , CASE WHEN mlt.[Sales_HL] > 0 THEN mlt.[Sales_HL]   
        ELSE 0  
        END AS 'SalesHl'
      , mlt.[PDT_HL]
      , mlt.[BGT_HL]
      , mlw.[AvgTemp]
      , mlw.[AvgRain]
      , mlw.[AvgSun]
      , CASE 
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 12 AND 21 THEN 1
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 42 AND 53  THEN 1
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2021 THEN 1

        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 12 AND 21 THEN 1
        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 42 AND 53  THEN 1
        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2021 THEN 1
        ELSE 0  
        END AS 'IsLockdown'
    FROM [FC_Tool].[dbo].[ML_Table] AS mlt
    INNER JOIN [FC_Tool].[dbo].[ML_Weather] AS mlw ON mlw.[Calweek] = mlt.[Calweek]
    WHERE 
        --mlt.[Country] = 'CZ' AND
        mlt.[DP_SKU] IS NOT NULL
        AND mlt.[PrimaryPack] IS NOT NULL
        AND mlt.[Sales_HL] IS NOT NULL
        AND [PrimaryPack] IN ('KEG WOODEN', 'KEG', 'KEG ONE WAY', 'TANK') --ON-TRADE
        --AND [PrimaryPack] IN ('NRB', 'CAN', 'RB', 'PET') --OFF-TRADE
  ) AS t
--WHERE  
    
    --AND SHORT_SKU IN ('06892') --'11276','02605', '02115', '06892'
    --AND [Year] < 2021
GROUP BY t.[Country], t.[Year], t.[Week], t.[Workdays], t.SHORT_SKU, t.IsLockdown, t.[ProductGroup], t.[PrimaryPack]


--SELECT * FROM @Temp

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
    , (SELECT TOP(1)
        SalesHl
    FROM @Temp AS w1
    WHERE w1.SkuShort = t.SkuShort
        AND w1.[Year] = t.[Year] - 1
        AND w1.[Week] = CASE WHEN t.Week <= 52 THEN t.Week ELSE 52  END 
        ) AS PrevYearSalesHl1
    ,(SELECT TOP(1)
        SalesHl
    FROM @Temp AS w1
    WHERE w1.SkuShort = t.SkuShort
        AND w1.[Year] = t.[Year] - 2
        AND w1.[Week] = CASE WHEN t.Week <= 52 THEN t.Week ELSE 52  END 
        ) AS PrevYearSalesHl2
    , [OldPredSalesHl]
FROM @Temp AS t
--WHERE [Year] NOT IN (2018, 2021)
ORDER BY  [Country], [Year], [Week]