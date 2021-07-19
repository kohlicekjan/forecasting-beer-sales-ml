SET NOCOUNT ON

DECLARE @TempNumberWorkdays TABLE
(
    [ID] VARCHAR(50) primary key,
    [NumberWorkdays] int
)

DECLARE @Temp TABLE
(
    [ID] VARCHAR(50) primary key,
    [SkuShort] VARCHAR(50),
    [Brand] VARCHAR(250),
    -- [SubBrand] VARCHAR(250),
    -- [ProductGroup] VARCHAR(50),
    -- [PrimaryPack] VARCHAR(50),
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


INSERT INTO @TempNumberWorkdays
    ([ID], [NumberWorkdays])
SELECT 
    [Country] + SUBSTRING([Calweek], 1, 4) + CONVERT(varchar(2), CAST(SUBSTRING([Calweek], 5, 2) AS int))
    , [Workdays]
FROM [FC_Tool].[dbo].[ML_Workdays]


INSERT INTO @Temp
    ([ID],
    [SkuShort],
    [Brand],
    -- [SubBrand], 
    -- [ProductGroup], 
    -- [PrimaryPack], 
    [Country], [Year], [Week], [NumberWorkdays], [AvgTemp], [AvgRain], [AvgSun], [IsLockdown], [PdtHl], [BgtHl], [OldPredSalesHl], [SalesHl])
SELECT
    t.[Country] + t.SHORT_SKU + t.[Year] + CONVERT(varchar(2),CAST(t.[Week] AS int))
    , t.SHORT_SKU
    , t.[Brand]
    -- , t.[SubBrand]
    -- , t.[ProductGroup]
    -- , t.[PrimaryPack]
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
    --   , mlt.[SubBrand]
    --   , mlt.[ProductGroup]
    --   , mlt.[PrimaryPack]
      , mlt.[LF1_HL]
      , mlt.[Sales_HL] 
      , CASE WHEN mlt.[Sales_HL] <= 0 THEN NULL
        ELSE mlt.[Sales_HL]  
        END AS 'SalesHl'
      , mlt.[PDT_HL]
      , mlt.[BGT_HL]
      , mlw.[AvgTemp]
      , mlw.[AvgRain]
      , mlw.[AvgSun]
      , CASE 
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 12 AND 21 THEN 1
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 42 AND 53  THEN 1
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2021 AND mlt.[Week] BETWEEN 1 AND 20  THEN 1
        WHEN mlt.[Country] = 'CZ' AND mlt.[Year] = 2021 THEN 0

        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 12 AND 21 THEN 1
        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2020 AND mlt.[Week] BETWEEN 42 AND 53  THEN 1
        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2021 AND mlt.[Week] BETWEEN 1 AND 20 THEN 1
        WHEN mlt.[Country] = 'SK' AND mlt.[Year] = 2021 THEN 0
        ELSE 0  
        END AS 'IsLockdown'
    FROM [FC_Tool].[dbo].[ML_Table] AS mlt
        LEFT JOIN [FC_Tool].[dbo].[ML_Weather] AS mlw ON mlw.[Calweek] = mlt.[Calweek]
    WHERE 
        mlt.[DP_SKU] IS NOT NULL
        AND mlt.[PrimaryPack] IS NOT NULL
        AND [PrimaryPack] IN ('KEG WOODEN', 'KEG', 'KEG ONE WAY', 'TANK') --ON-TRADE
        --AND [PrimaryPack] IN ('NRB', 'CAN', 'RB', 'PET') --OFF-TRADE
  ) AS t
GROUP BY t.[Country], t.[Year], t.[Week], t.[Workdays], t.SHORT_SKU, t.IsLockdown , t.[Brand]--, t.[PrimaryPack], t.[ProductGroup], t.[SubBrand], 


SELECT
    t.[SkuShort]
    , t.[Brand]
    -- , t.[SubBrand]
    -- , t.[ProductGroup]
    -- , t.[PrimaryPack]
    , t.[Country]
    , t.[Year] 
    , t.[Week]
    , t.[NumberWorkdays]
    , (SELECT TOP (1)
        [NumberWorkdays]
    FROM @TempNumberWorkdays AS pnw
    WHERE pnw.[ID] = t.[Country] 
        + CONVERT(varchar(4), (CASE WHEN (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1 END))
        + CONVERT(varchar(2), (CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52  END))
        ) AS PrevNumberWorkdays    
    , (SELECT TOP (1)
        [NumberWorkdays]
    FROM @TempNumberWorkdays AS nnw
    WHERE nnw.[ID] = t.[Country] 
        + CONVERT(varchar(4), (CASE WHEN (t.Week + 1) > 52 THEN t.[Year] ELSE t.[Year] + 1 END))
        + CONVERT(varchar(2), (CASE WHEN (t.Week + 1) > 52 THEN (t.Week + 1) ELSE 1 END))
        )AS NextNumberWorkdays
    , ISNULL(t.[AvgTemp], (SELECT AVG(AvgTemp)
    FROM [FC_Tool].[dbo].[ML_Weather]
    WHERE SUBSTRING([Calweek], 1, 4) > t.[Year]-3 AND SUBSTRING([Calweek], 5, 2)=t.[Week])) AS AvgTemp
    , ISNULL(t.[AvgRain], (SELECT AVG(AvgRain)
    FROM [FC_Tool].[dbo].[ML_Weather]
    WHERE SUBSTRING([Calweek], 1, 4) > t.[Year]-3 AND SUBSTRING([Calweek], 5, 2)=t.[Week])) AS AvgRain
    , ISNULL(t.[AvgSun],(SELECT AVG(AvgSun)
    FROM [FC_Tool].[dbo].[ML_Weather]
    WHERE SUBSTRING([Calweek], 1, 4) > t.[Year]-3 AND SUBSTRING([Calweek], 5, 2)=t.[Week])) AS AvgSun
    , t.[IsLockdown]
    , t.[PdtHl]
    , pw1.PdtHl AS PrevWeekPdtHl1
    , t.[BgtHl] 
    , t.SalesHl
    , pw1.SalesHl AS PrevWeekSalesHl1
    , (SELECT TOP(1)
        w2.SalesHl
    FROM @Temp AS w2
    WHERE w2.[ID] = t.[Country] 
        + t.[SkuShort] 
        + CONVERT(varchar(4), (CASE WHEN (t.Week - 2) > 0 THEN t.[Year] ELSE t.[Year] - 1 END)) 
        + CONVERT(varchar(2), (CASE WHEN (t.Week - 2) > 0 THEN (t.Week -2) WHEN (t.Week - 2) = 0 THEN 52 ELSE 51  END))
        ) AS PrevWeekSalesHl2
    , (SELECT TOP(1)
        y1.SalesHl
    FROM @Temp AS y1
    WHERE y1.[ID] = t.[Country] 
        + t.[SkuShort] 
        + CONVERT(varchar(4), (t.[Year] - 1))
        + CONVERT(varchar(2), (CASE WHEN t.Week <= 52 THEN t.Week ELSE 52  END))
        ) AS PrevYearSalesHl1
    , (SELECT TOP(1)
        y2.SalesHl
    FROM @Temp AS y2
    WHERE y2.[ID] = t.[Country] 
        + t.[SkuShort] 
        + CONVERT(varchar(4), (t.[Year] - 2)) 
        + CONVERT(varchar(2), (CASE WHEN t.Week <= 52 THEN t.Week ELSE 52  END))
        ) AS PrevYearSalesHl2
    , t.[OldPredSalesHl]
FROM @Temp AS t
    LEFT JOIN @Temp AS pw1 ON pw1.[ID] = t.[Country] 
        + t.[SkuShort]
        + CONVERT(varchar(4), (CASE WHEN (t.Week - 1) > 0 THEN t.[Year] ELSE t.[Year] - 1 END))
        + CONVERT(varchar(2), (CASE WHEN (t.Week - 1) > 0 THEN (t.Week - 1) ELSE 52  END))
--WHERE t.[Year] = 2021 AND t.[Week] BETWEEN 25 AND 30
ORDER BY t.[Year], t.[Week], t.SkuShort, t.[Country]