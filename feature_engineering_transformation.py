import pandas as pd
import numpy as np

def featureTransformation(crime, population, walesDeprivation, englandDeprivation):
    
    # Copy of dataframes is created and used to ensure original dataframes are not overwritten    
    crime = crime.copy()
    population = population.copy()
    walesDeprivation = walesDeprivation.copy()
    englandDeprivation = englandDeprivation.copy()
    
    ## -----------------------------------------------------------------------
    ## Crime data feature transformations and additions 
    ## -----------------------------------------------------------------------
    
    crime['YEAR'] = crime['YEAR'].astype(int)
    crime['MONTH'] = crime['MONTH'].astype(int)
    
    # Clean Force names to be just the name of the police force without "Force" or other keywords
    crime['FORCE'] = crime['REPORTED_BY'].str.replace("Police", "").str.strip()
    crime.loc[crime['FORCE'].str.contains('Metropolitan', case=False), 'FORCE'] = 'Metropolitan'
    crime['FORCE'] = crime['FORCE'].str.title()

    # Standardize 'Crime type'
    crime['CRIME_TYPE'] = crime['CRIME_TYPE'].str.strip().str.title()

    ## Addition of Quarter column for quarterly analysis of crime
    monthToQuarter = {
        1: 1, 2: 1, 3: 1,
        4: 2, 5: 2, 6: 2,
        7: 3, 8: 3, 9: 3,
        10: 4, 11: 4, 12: 4
    }
    
    crime['QUARTER'] = crime['MONTH'].map(monthToQuarter)
    
    ## Addition of District column to broaden crime to general districts within forces rather than specific LDOAs 
    crime['DISTRICT'] = crime['LSOA_NAME'].str.rsplit(' ', n=1).str[0].str.strip()
    
    # Dropped Reported by column since a cleaner, standardised Force column was derived from it
    crime = crime.drop(columns=["FALLS_WITHIN", "REPORTED_BY"])
    
    ## ----------------------------------------------------
    ## Population estimation & feature transforming
    ## ----------------------------------------------------

    # Filters the population tables to include only the records with 2021 to 2024
    p2021 = population[population['YEAR'] == 2021].set_index('FORCE_NAME')['TOTAL_POPULATION']
    p2024 = population[population['YEAR'] == 2024].set_index('FORCE_NAME')['TOTAL_POPULATION']
    
    # Formula to calculate annual growth between 2021 to 2024
    annualGrowthRate = ((p2024/p2021) ** (( (1/3)))) - 1

    # Fetches the latest 2024 population for each force and the annual growth rate with the above formula
    futureRows = []
    for force in population['FORCE_NAME'].unique():
        popLatest = p2024[force]
        rate = annualGrowthRate[force]
        
        # Estimates 2025 & 2026
        pop2025 = round(popLatest * (1 + rate))
        pop2026 = round(pop2025 * (1 + rate))
        
        # Appends the rows to an array
        futureRows.append({'FORCE_NAME': force, 'YEAR': 2025, 'TOTAL_POPULATION': pop2025})
        futureRows.append({'FORCE_NAME': force, 'YEAR': 2026, 'TOTAL_POPULATION': pop2026})
    
    # Converts the array into a dataframe and concatenates it to the population table
    popEstimateDf = pd.DataFrame(futureRows)
    populationComplete = pd.concat([population, popEstimateDf], ignore_index=True)

    # Clean Force names to be just the name of the police force without "Force" or other keywords
    populationComplete['FORCE'] = populationComplete['FORCE_NAME'].str.replace("Police", "").str.strip()
    populationComplete.loc[populationComplete['FORCE'].str.contains('Metropolitan', case=False), 'FORCE'] = 'Metropolitan'
    populationComplete['FORCE'] = populationComplete['FORCE'].str.title()
    
    # Drops FORCE_NAME column since standardised FORCE column was created
    populationComplete = populationComplete.drop(columns=['FORCE_NAME'])
    
    # Join the Crime and population data by the Force and Year with a left join
    crimePopulation = pd.merge(crime, populationComplete, on=['FORCE', 'YEAR'], how='left')
    
    ## ----------------------------------------------------
    ## Deprivation cleaning and feature transforming
    ## ----------------------------------------------------
    
    # Maps "South Wales" force to Welsh LSOA deprivation records by checking active crime LSOA codes
    southWalesCrime = crimePopulation[crimePopulation['FORCE'] == 'South Wales']
    targetLsoas = southWalesCrime['LSOA_CODE'].unique()
    walesDeprivation['FORCE'] = 'South Wales'
    walesDeprivation['FORCE'] = walesDeprivation['FORCE'].where(
        walesDeprivation['LSOA_CODE'].isin(targetLsoas), 
        None
    )

    # Map of English forces boroughs to their respective police force 
    englandForceMap = {
        # Metropolitan
        'Barking and Dagenham': 'Metropolitan',
        'Barnet': 'Metropolitan',
        'Bexley': 'Metropolitan',
        'Brent': 'Metropolitan',
        'Bromley': 'Metropolitan',
        'Camden': 'Metropolitan',
        'Croydon': 'Metropolitan',
        'Ealing': 'Metropolitan',
        'Enfield': 'Metropolitan',
        'Greenwich': 'Metropolitan',
        'Hackney': 'Metropolitan',
        'Hammersmith and Fulham': 'Metropolitan',
        'Haringey': 'Metropolitan',
        'Harrow': 'Metropolitan',
        'Havering': 'Metropolitan',
        'Hillingdon': 'Metropolitan',
        'Hounslow': 'Metropolitan',
        'Islington': 'Metropolitan',
        'Kensington and Chelsea': 'Metropolitan',
        'Kingston upon Thames': 'Metropolitan',
        'Lambeth': 'Metropolitan',
        'Lewisham': 'Metropolitan',
        'Merton': 'Metropolitan',
        'Newham': 'Metropolitan',
        'Redbridge': 'Metropolitan',
        'Richmond upon Thames': 'Metropolitan',
        'Southwark': 'Metropolitan',
        'Sutton': 'Metropolitan',
        'Tower Hamlets': 'Metropolitan',
        'Waltham Forest': 'Metropolitan',
        'Wandsworth': 'Metropolitan',
        'Westminster': 'Metropolitan',
        'City of London': 'Metropolitan',
        # West Midlands
        'Birmingham': 'West Midlands',
        'Coventry': 'West Midlands',
        'Dudley': 'West Midlands',
        'Sandwell': 'West Midlands',
        'Solihull': 'West Midlands',
        'Walsall': 'West Midlands',
        'Wolverhampton': 'West Midlands',
        # Sussex
        'Adur': 'Sussex',
        'Arun': 'Sussex',
        'Brighton and Hove': 'Sussex',
        'Chichester': 'Sussex',
        'Crawley': 'Sussex',
        'Eastbourne': 'Sussex',
        'Hastings': 'Sussex',
        'Horsham': 'Sussex',
        'Lewes': 'Sussex',
        'Mid Sussex': 'Sussex',
        'Rother': 'Sussex',
        'Wealden': 'Sussex',
        'Worthing': 'Sussex',
    }
    
    # Uses above map to define the force for each LSOA
    englandDeprivation['FORCE'] = englandDeprivation['LOCAL_AUTHORITY_NAME'].map(englandForceMap)
    
    # Standardise English LSOA features
    englandDeprivation['DEPRIVATION_PERCENTILE'] = (englandDeprivation['IMD_RANK'] - 1) / (englandDeprivation['IMD_RANK'].max() - 1)
    englandDeprivation['IS_DECILE_1'] = np.where(englandDeprivation['IMD_DECILE'] == 1, 1, 0)
    englandDeprivation['INCOME_DECILE'] = englandDeprivation['INCOME_DECILE']

    # Standardise Welsh LSOA features
    walesDeprivation['DEPRIVATION_PERCENTILE'] = (walesDeprivation['WIMD_RANK'] - 1) / (walesDeprivation['WIMD_RANK'].max() - 1)
    walesDeprivation['IS_DECILE_1'] = np.where(walesDeprivation['WIMD_DECILE'] == 1, 1, 0)
    walesDeprivation['INCOME_DECILE'] = walesDeprivation['INCOME_DECILE']

    # Join the 2 deprivation tables together
    combined_iod = pd.concat([
        englandDeprivation[['LSOA_CODE', 'FORCE', 'DEPRIVATION_PERCENTILE', 'INCOME_DECILE', 'IS_DECILE_1']],
        walesDeprivation[['LSOA_CODE', 'FORCE', 'DEPRIVATION_PERCENTILE', 'INCOME_DECILE', 'IS_DECILE_1']]
    ], ignore_index=True)
    
    # Join the crime and population merged table with the joint deprivation tables
    combinedCleanDf = pd.merge(
    crimePopulation, 
    combined_iod[['LSOA_CODE', 'DEPRIVATION_PERCENTILE', 'INCOME_DECILE', 'IS_DECILE_1']], 
    on=['LSOA_CODE'], 
    how='left'
    )
    
    # Filter out of boundary districts logged by Metropolitan police
    valid_met_districts = list(englandForceMap.keys())
    combinedCleanDf = combinedCleanDf[
        (combinedCleanDf['FORCE'] != 'Metropolitan') | (combinedCleanDf['DISTRICT'].isin(valid_met_districts))
    ]
        
    return combinedCleanDf

# Aggregate Layer and export layer combined (FORCE X YEAR X QUARTER X DISTRICT X CRIME_TYPE)
def aggregationExport(combinedCleanDf):

    # Defined grain
    grain = ['FORCE', 'YEAR', 'QUARTER', 'DISTRICT', 'CRIME_TYPE']
    
    # The aggregation
    aggregatedDf = combinedCleanDf.groupby(grain).agg(
        # Counts number of crimes per the grain
        IncidentCount=('CRIME_ID', 'count'),
        
        # Records the total population per the grain
        TotalPopulation=('TOTAL_POPULATION', 'first'),
        
        # Records the number of LSOAs the grain spanned
        UniqueLSOAsSpanned=('LSOA_CODE', 'nunique'),
        
        # Deprivation metrics in regard to the grain
        AvgDeprivationPercentile=('DEPRIVATION_PERCENTILE', 'mean'),
        AvgIncomeDecile=('INCOME_DECILE', 'mean'),
    ).reset_index()

    # Crime rate per 1000 people
    aggregatedDf['CrimeRatePer1k'] = (
        aggregatedDf['IncidentCount'] / aggregatedDf['TotalPopulation']
    ) * 1000

    # Average deprivation percentile per the grain 
    aggregatedDf['AvgDeprivationPercentile'] = (aggregatedDf['AvgDeprivationPercentile'] * 100).round(2)
    
    # Standardising the aggregation metrics
    aggregatedDf['AvgIncomeDecile'] = aggregatedDf['AvgIncomeDecile'].round(2)
    aggregatedDf['CrimeRatePer1k'] = aggregatedDf['CrimeRatePer1k'].round(4)
    
    grainDuplicates = aggregatedDf.duplicated(subset=['FORCE', 'YEAR', 'QUARTER', 'DISTRICT', 'CRIME_TYPE']).sum()
    print(f"Validation - Duplicate records at reporting grain: {grainDuplicates}")

    # Check for number of null values in the data
    print("\nFinal Missing Value Summary:")
    print(aggregatedDf[['FORCE', 'YEAR', 'QUARTER', 'DISTRICT', 'CRIME_TYPE']].isnull().sum())

    # General summary of final dataset statistics
    print(f"\n--- Final Dataset Summary Statistics ---")
    print(f"Total Grain Rows: {len(aggregatedDf)}")
    print(f"Unique Police Forces Covered: {aggregatedDf['FORCE'].nunique()} ({aggregatedDf['FORCE'].unique()})")
    print(f"Temporal Window Span: {aggregatedDf['YEAR'].min()} to {aggregatedDf['YEAR'].max()}")
    
    aggregatedDf.to_csv('processedAndAggregatedCrimeData.csv', index=False)
    print("\nData Sucessfully converted into CSV file.")
    
    return aggregatedDf
