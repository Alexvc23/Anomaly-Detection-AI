
--------------------------------Entire t_compte_rendu with source 'erp_khubeo'

--  SELECT TOP (10000) *
-- FROM [BDERP].[dbo].[T_COMPTE_RENDU]
-- WHERE CR_SOURCE like 'ERP_KHUBEO'


----- only data sources
-- SELECT TOP (10000) CR_SOURCE
--FROM [BDERP].[dbo].[T_COMPTE_RENDU]
----WHERE CR_SOURCE like 'ERP_khubeo'
--GROUP BY CR_SOURCE



----- groupying data types and data sources---------------------
-- SELECT TOP (10000) CR_SOURCE, CR_TYPE_DATA
-- FROM [BDERP].[dbo].[T_COMPTE_RENDU]
-- --WHERE CR_SOURCE like 'ERP_khubeo'
-- GROUP BY CR_SOURCE, CR_TYPE_DATA


-------------------------------------------------------
--SELECT TOP 10000 *
--FROM [BDERP].[dbo].[T_COMPTE_RENDU]
--WHERE CR_SOURCE LIKE 'ERP_khubeo' and CR_TYPE_DATA like 'HEBERGEMENT'
--  --AND CR_DATE > '2023-01-01';
--order by ID_COMPTE_RENDU desc;

---------------------Client example that contains only SERVICE. 
-- SELECT 
--    CAST(CR_DATE AS DATE) AS Date,
--    CR_TYPE_DATA,
--    COUNT(*) AS TotalRecords,
--    SUM(CR_MONTANT_TTC) AS TotalMontantTTC,
--    SUM(CR_MONTANT_HT) AS TotalMontantHT,
--    SUM(CR_TVA) AS TotalTVA,
--    SUM(CR_QUANTITE) AS TotalQuantite
-- FROM [BDERP].[dbo].[T_COMPTE_RENDU]
-- WHERE CR_SOURCE LIKE 'ERP_khubeo'
--  AND ID_CLIENT = 88
--  AND ID_DOSSIER = '11204'
-- GROUP BY CAST(CR_DATE AS DATE), CR_TYPE_DATA
-- ORDER BY Date DESC, CR_TYPE_DATA;

-------------------------------------------Analysis to validate the tva percentage applied to all the folder to all the client of the first 10000 lines
--SELECT top(10000)
--    CAST(CR_DATE AS DATE) AS Date,
--    CR_TYPE_DATA,
--	ID_CLIENT,
--    ID_DOSSIER,
--    COUNT(*) AS TotalRecords,
--    SUM(CR_MONTANT_TTC) AS TotalMontantTTC,
--    SUM(CR_MONTANT_HT) AS TotalMontantHT,
--    SUM(CR_TVA) AS TotalTVA,
--    SUM(CR_QUANTITE) AS TotalQuantite,
--    CASE 
--        WHEN SUM(CR_MONTANT_HT) > 0 
--            THEN (SUM(CR_TVA) / SUM(CR_MONTANT_HT))
--        ELSE NULL 
--    END AS PercentageCR_TVA
--FROM [BDERP].[dbo].[T_COMPTE_RENDU]
--WHERE 
--    CR_SOURCE LIKE 'erp_khubeo'
--    --AND ID_CLIENT = 5
--GROUP BY 
--    CAST(CR_DATE AS DATE),
--    CR_TYPE_DATA,
--	ID_CLIENT,
--    ID_DOSSIER
--HAVING 
--    SUM(CR_MONTANT_HT) > 0
--ORDER BY 
--    Date DESC, 
--    CR_TYPE_DATA,
--    ID_DOSSIER;

---------------------Client example that conatint data type HEBERGEMENT and SERVICE. 
--SELECT 
--    CAST(CR_DATE AS DATE) AS Date,
--    CR_TYPE_DATA,
--    COUNT(*) AS TotalRecords,
--    SUM(CR_MONTANT_TTC) AS TotalMontantTTC,
--    SUM(CR_MONTANT_HT) AS TotalMontantHT,
--    SUM(CR_TVA) AS TotalTVA,
--    SUM(CR_QUANTITE) AS TotalQuantite
--FROM [BDERP].[dbo].[T_COMPTE_RENDU]
--WHERE CR_SOURCE LIKE 'erp_khubeo'
--  AND ID_CLIENT = 5
--  AND ID_DOSSIER = '125'
--GROUP BY CAST(CR_DATE AS DATE), CR_TYPE_DATA
--ORDER BY Date DESC, CR_TYPE_DATA;

---------------------Client example that conatint data type HEBERGEMENT
SELECT TOP(1000)
    CAST(CR_DATE AS DATE) AS Date,
    CR_TYPE_DATA,
    COUNT(*) AS TotalRecords,
    CASE 
        WHEN SUM(CR_MONTANT_TTC) = 0 THEN SUM(CR_MONTANT_HT) * 1.10
        ELSE SUM(CR_MONTANT_TTC)
    END AS TotalMontantTTC,
    CASE 
        WHEN SUM(CR_MONTANT_HT) = 0 THEN SUM(CR_MONTANT_TTC) / 1.10
        ELSE SUM(CR_MONTANT_HT)
    END AS TotalMontantHT,
    CASE 
        WHEN SUM(CR_TVA) = 0 THEN 
            CASE 
                WHEN SUM(CR_MONTANT_HT) > 0 THEN SUM(CR_MONTANT_HT) * 0.10
                ELSE SUM(CR_MONTANT_TTC) - (SUM(CR_MONTANT_TTC) / 1.10)
            END
        ELSE SUM(CR_TVA)
    END AS TotalTVA
    --SUM(CR_QUANTITE) AS TotalQuantite
FROM [BDERP].[dbo].[T_COMPTE_RENDU]
WHERE CR_SOURCE LIKE 'erp_khubeo'
  AND ID_CLIENT = 5
  AND ID_DOSSIER = '125'
  AND CR_TYPE_DATA = 'HEBERGEMENT'
  AND (CR_MONTANT_TTC = 0 OR CR_MONTANT_HT = 0)
GROUP BY CAST(CR_DATE AS DATE), CR_TYPE_DATA
ORDER BY Date DESC, CR_TYPE_DATA;


select * from [BDERP].[dbo].[T_COMPTE_RENDU] where ID_CLIENT = 5 and ID_DOSSIER = '125' and CR_TYPE_DATA = 'HEBERGEMENT' and CR_SOURCE like 'erp_khubeo' and CR_MONTANT_TTC = 0

-------------------liste requests
--select top (10000) * 
--from BDCockpitPerformance.dbo.T_LISTE_REQUETES
--where ID_SD = 'SOURCE3' OR  ID_SD = 'SOURCE4'

---------------------------------------------------Analyse to determine the TVA applied to all the business----------------

--SELECT 
--   ID_CLIENT,
--   ID_DOSSIER,
--   COUNT(*) AS TotalPercentageCR_TVA_10,
--	SUM(TotalRecords) as TotalLInesByClientAndFolder
--FROM (
--   SELECT 
--       CAST(CR_DATE AS DATE) AS Date,
--       CR_TYPE_DATA,
--       ID_CLIENT,
--       ID_DOSSIER,
--       COUNT(*) AS TotalRecords,
--       SUM(CR_MONTANT_TTC) AS TotalMontantTTC,
--       SUM(CR_MONTANT_HT) AS TotalMontantHT,
--       SUM(CR_TVA) AS TotalTVA,
--       SUM(CR_QUANTITE) AS TotalQuantite,
--       CASE 
--           WHEN SUM(CR_MONTANT_HT) > 0 
--           THEN CAST(
--               ((SUM(CR_TVA) / SUM(CR_MONTANT_HT)) * 100)
--               AS DECIMAL(10,2)
--           )
--           ELSE NULL 
--       END AS PercentageCR_TVA
--   FROM [BDERP].[dbo].[T_COMPTE_RENDU]
--   WHERE CR_SOURCE LIKE 'erp_khubeo'
--	and CR_TYPE_DATA = 'HEBERGEMENT'
--   GROUP BY 
--       CAST(CR_DATE AS DATE),
--       CR_TYPE_DATA,
--       ID_CLIENT,
--       ID_DOSSIER
--   HAVING SUM(CR_MONTANT_HT) > 0
--) AS SubQuery
--WHERE PercentageCR_TVA = 10.0
--GROUP BY ID_CLIENT, ID_DOSSIER
--ORDER BY ID_CLIENT, ID_DOSSIER;

