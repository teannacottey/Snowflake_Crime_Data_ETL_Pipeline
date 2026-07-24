import os
import pandas as pd
from pathlib import Path

def getCrimeData(forces, basePath="C:\Users\noahe\Documents\Rockborne\Advance\2025crime"):
    """Ingests crime data CSVs for specified police forces from nested folders.

    Parameters:
    - forces (list): List of force names to filter by (e.g. ['metropolitan',
    'surrey'])
    - basePath (str): Root directory containing monthly data folders

    Returns:
    - pd.DataFrame: Combined DataFrame of all ingested crime records
    """
    allData = []
    
    projectRoot = Path.cwd()

    # Standardize input force names to lowercase for robust matching
    forces_clean = [f.lower() for f in forces]

    if not os.path.exists(basePath):
        print(f"Error: Base directory '{basePath}' does not exist.")
        return pd.DataFrame()

    # Iterate through each folder inside the base directory
    for folder in os.listdir(basePath):
        filePath = os.path.join(basePath, folder)

        if os.path.isdir(filePath):
            for file in os.listdir(filePath):
                file_lower = file.lower()

                # Check if any specified force name is in the filename
                if any(force in file_lower for force in forces_clean):
                    file_path = os.path.join(filePath, file)

                    try:
                        df = pd.read_csv(file_path)
                        df["Month"] = folder
                        allData.append(df)
                    except Exception as e:
                        print(f"Error reading {file_path}: {e}")

    # Concatenate all loaded DataFrames
    if allData:
        masterDf = pd.concat(allData, ignore_index=True)
        print(
            f"Successfully loaded {len(masterDf)} records across {len(allData)} files."
        )
        return masterDf
    else:
        print("No matching data found to process.")
        return pd.DataFrame()