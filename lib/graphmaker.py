import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import seaborn as sns

def pie_chart(json_data, column_name):
    """
    Takes a JSON input, converts it to a Pandas DataFrame, and creates a pie chart.

    Args:
        json_data (list of dict): The JSON input to be converted to a DataFrame.
        column_name (str): The column name to group data for the pie chart.

    Returns:
        matplotlib.figure.Figure: The generated pie chart figure.
    """
    # Convert JSON data to a Pandas DataFrame
    df = pd.DataFrame(json_data)

    # Group data by the specified column and calculate the counts
    data_counts = df[column_name].value_counts()

    # Create a pie chart
    fig, ax = plt.subplots(figsize=(8, 8))
    sns.set_palette("pastel")
    ax.pie(
        data_counts,
        labels=data_counts.index,
        autopct='%1.1f%%',
        startangle=90,
        textprops={'fontsize': 12}
    )
    ax.set_title(f"Distribution of {column_name}", fontsize=16)

    # Return the figure
    return fig