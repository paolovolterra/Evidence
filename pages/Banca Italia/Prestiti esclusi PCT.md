# Prestiti al Mezzogiorno (esclusi PCT)
per regione e target di clientela; consistenze in Mln€  
_elaborazioni su dati Banca d'Italia, tabella TDB10295_

```sql unique_items
WITH nuts (value, label) AS (
  VALUES
    ('ITF1','Abruzzo'),
    ('ITF2','Molise'),
    ('ITF3','Campania'),
    ('ITF4','Puglia'),
    ('ITF5','Basilicata'),
    ('ITF6','Calabria'),
    ('ITG1','Sicilia'),
    ('ITG2','Sardegna'),
    ('ITF','Sud'),
    ('ITG','Isole'),
    ('IT','Italia'),
)
SELECT value, label
FROM nuts
ORDER BY value;
```

## Nel tempo

### Seleziona area
<Dropdown
  name=selected_item
  data={unique_items}
  value=value
  label=label
  defaultValue="IT"
/>

```sql prova
SELECT  DATA_OSS, NUT, target, VALORE
FROM bankit.TDB10295C
WHERE LOC_CTP = '${inputs.selected_item.value}'
  AND strftime('%m', DATA_OSS) = '06'
  AND SET_CTP IN ('600','S11','S14BI2')
  AND DATA_OSS > '2018-12-31'
ORDER BY DATA_OSS desc, target;
```

<DataTable
  data={prova}
  title="Tabella valori"
    download=true
  downloadFilename="prestiti_prova.csv"
  columns={[
    { key: "DATA_OSS", label: "Data" },
    { key: "target", label: "Target" },
    { key: "VALORE", label: "Valore assoluto" },
    { key: "quota_pct", label: "Quota (%)", format: "percent" }
  ]}
/>


<LineChart 
data={prova} 
x=DATA_OSS 
y=VALORE 
series=target 
type=stacked 
title="Andamento (valori assoluti)"
colorPalette={[
    "#ff0000",
    "#7f7f7f",
    "#007a53",
]}
/>


<BarChart 
data={prova} 
x=DATA_OSS 
y=VALORE 
series=target 
title="Andamento (percentuale)" 
type=stacked100
colorPalette={[
    "#ff0000",
    "#7f7f7f",
    "#007a53",
]}
/>

## Per categoria
```sql pivot_abs
WITH base AS (
  SELECT
    CAST(DATA_OSS AS DATE) AS d,
    LOC_CTP,
    TRIM(SET_CTP) AS serie,
    try_cast(replace(replace(VALORE,'.',''),',','.') AS DOUBLE) AS v
  FROM bankit.TDB10295C
  WHERE LOC_CTP = '${inputs.selected_item.value}'
    AND EXTRACT(MONTH FROM CAST(DATA_OSS AS DATE)) = 6
    AND SET_CTP IN ('600','S11','S14BI2')
    AND CAST(DATA_OSS AS DATE) > DATE '2018-12-31'
),
agg AS (
  SELECT d, serie, SUM(v) AS v
  FROM base
  GROUP BY d, serie
)
SELECT
  d AS DATA_OSS,
  COALESCE(SUM(CASE WHEN serie='600'    THEN v END),0)    AS "Famiglie consumatrici",
  COALESCE(SUM(CASE WHEN serie='S11'    THEN v END),0)    AS "Società non finanziarie",
  COALESCE(SUM(CASE WHEN serie='S14BI2' THEN v END),0)    AS "Famiglie produttrici"
FROM agg
GROUP BY d
ORDER BY d desc;
```

<DataTable data={pivot_abs} title="Prestiti per categoria (Mln€)" download=true downloadFilename="pivot_prestiti_valori.csv" />



```sql pivot_pct
WITH base AS (
  SELECT
    CAST(DATA_OSS AS DATE) AS d,
    LOC_CTP,
    TRIM(SET_CTP) AS serie,
    try_cast(replace(replace(VALORE,'.',''),',','.') AS DOUBLE) AS v
  FROM bankit.TDB10295C
  WHERE LOC_CTP = '${inputs.selected_item.value}'
    AND EXTRACT(MONTH FROM CAST(DATA_OSS AS DATE)) = 6
    AND SET_CTP IN ('600','S11','S14BI2')
    AND CAST(DATA_OSS AS DATE) > DATE '2018-12-31'
),
agg AS (
  SELECT d, serie, SUM(v) AS v
  FROM base
  GROUP BY d, serie
),
tot AS (
  SELECT d, SUM(v) AS tot
  FROM agg
  GROUP BY d
)
SELECT
  a.d AS DATA_OSS,
  ROUND(100 * SUM(CASE WHEN a.serie='600'    THEN a.v END) / NULLIF(t.tot,0), 1) AS "Fam.consumatrici",
  ROUND(100 * SUM(CASE WHEN a.serie='S14BI2' THEN a.v END) / NULLIF(t.tot,0), 1) AS "Fam.produttrici",
  ROUND(100 * SUM(CASE WHEN a.serie='S11'    THEN a.v END) / NULLIF(t.tot,0), 1) AS "Soc.non finanziarie",
  ROUND(100 * SUM(a.v)/NULLIF(t.tot,0),1) AS "Totale (%)"
FROM agg a
JOIN tot t USING (d)
GROUP BY a.d, t.tot
ORDER BY a.d desc;
```

<DataTable data={pivot_pct} title="Prestiti per categoria (%)" download=true downloadFilename="pivot_prestiti_percentuali.csv" />