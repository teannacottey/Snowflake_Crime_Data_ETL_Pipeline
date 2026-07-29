# ingestion layer #

"""
LIBRARIES
"""

import pandas as pd
import requests
import json
import time
import tempfile
import zipfile

from pathlib import Path
from urllib.parse import urljoin
from bs4 import BeautifulSoup


"""
FUNCTION
"""

def get_crime_data(forces, start_date, end_date):
    """
    Download crime data (CSV files) for selected police forces, between selected dates.
    and dates.

    Parameters
    ----------
    forces : list
        Police.uk force IDs.

    start_date : str
        First month in YYYY-MM format.

    end_date : str
        Last month in YYYY-MM format.

    Returns
    -------
    dict
        One pandas DataFrame for each police force.
    """

    # 1. Open the custom-download page
    form_url = "https://data.police.uk/data/"           # URL
    session = requests.Session()                        # create a web session
    
    form_response = session.get(form_url, timeout=30)   # Send a GET request to retrieve the HTML form
    form_response.raise_for_status()                    # timeout=30 stops the request if the server does not respond

    # 2. Extract the security token from the form
    soup = BeautifulSoup(form_response.text, "html.parser")                  # parse html
    token_element = soup.select_one("input[name='csrfmiddlewaretoken']")     # locate CSRF token

    if token_element is None:
        raise RuntimeError("Could not find the Police.uk security token")    # error check incase token cannot be found
    csrf_token = token_element["value"]                                      # extract element's value attribute

    # 3. Submit the selected dates and forces
    form_data = {
        "csrfmiddlewaretoken": csrf_token,
        "date_from": start_date,
        "date_to": end_date,
        "forces": forces,
        "include_crime": "on"     # outcomes and stop-and-search are not requested
    }

    request_response = session.post(       # submit the completed form using an HTTP POST request
        form_url,
        data=form_data,
        headers={"Referer": form_url},
        timeout=60                         # 60 second count
    )
    request_response.raise_for_status()    # raise an exception

    # 4. Find the URL used to check download progress
    soup = BeautifulSoup(request_response.text, "html.parser")    # parse HTML
    config_element = soup.select_one("#download-config")          # Find the HTML element containing the download configuration

    if config_element is None:
        raise RuntimeError(
            "Police.uk did not create a download request. "
            "Check the force IDs and date range.")            # error check

    download_config = json.loads(config_element.get_text())     # extract JSON
    progress_url = urljoin(form_url, download_config["url"])

    # 5. Wait for Police.uk to generate the ZIP
    print("Police.uk is generating the download...")       # comment for user
    zip_url = None                                         # start with no zip URL

    for attempt in range(150):
        progress_response = session.get(progress_url, timeout=30)
        progress_response.raise_for_status()                            # raise exception if status request failed
        progress = progress_response.json()                             # JSON -> dictionary
        status = progress.get("status")

        if status == "ready":
            zip_url = progress["url"]
            break

        if status == "error":
            raise RuntimeError("Police.uk could not generate the download")
        time.sleep(2)

    if zip_url is None:
        raise TimeoutError("The download was not ready after five minutes")

    print("Download ready. Downloading ZIP...")      # comment for user

    # 6. Start downloading the generated ZIP
    zip_response = session.get(
        zip_url,
        stream=True,
        timeout=120      # allow 120 seconds
    )
    zip_response.raise_for_status()

    # 7. Store and open the ZIP safely on Windows
    with tempfile.TemporaryDirectory() as temp_directory:
        zip_path = (
            Path(temp_directory)
            / "police_crime_data.zip"
        )

        with zip_path.open("wb") as zip_file:
            for chunk in zip_response.iter_content(
                chunk_size=1024 * 1024):
                if chunk:
                    zip_file.write(chunk)

        print("ZIP downloaded. Reading CSV files...")
        
        results = {}     # create empty results dictionary

        with zipfile.ZipFile(zip_path) as archive:
            filenames = archive.namelist()

            for force in forces:
                force_files = [
                    filename
                    for filename in filenames
                    if filename.lower().endswith(
                        f"-{force}-street.csv"
                    )
                ]
                if not force_files:
                    print(
                        f"Warning: no files found for {force}"
                    )

                    results[force] = pd.DataFrame()
                    continue

                monthly_data = []

                for filename in force_files:
                    with archive.open(filename) as csv_file:
                        month_df = pd.read_csv(csv_file)

                    monthly_data.append(month_df)

                results[force] = pd.concat(
                    monthly_data,
                    ignore_index=True
                )

                print(
                    f"{force}: "
                    f"{len(force_files)} files, "
                    f"{len(results[force]):,} rows"
                )

    print("--------")
    print("Ingestion complete.")

    return results