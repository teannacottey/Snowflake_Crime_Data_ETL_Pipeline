## derive time attributes (will be added to once final data is availiable)
def yearConversion():
    print("hello")

## standardise crime category fields (will be added to once final data is availiable)
def textStandardisation():
    print("Hello")

## join 1-3 enrichment datasets (compatible grain, no "many to many joins", clear handling of temporal mismatches)

# Dictionary mapping Local Authority Districts to their respective Police Force (subject to change or not even needed at all depending on datasets)
force_lookup = {
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
    # South Wales
    'Bridgend': 'South Wales',
    'Cardiff': 'South Wales',
    'Merthyr Tydfil': 'South Wales',
    'Neath Port Talbot': 'South Wales',
    'Rhondda Cynon Taf': 'South Wales',
    'Swansea': 'South Wales',
    'Vale of Glamorgan': 'South Wales',
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

## map lsoa names 