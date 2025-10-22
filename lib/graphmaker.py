from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from dash import Dash, dcc, html
from dash.dependencies import Input, Output
import pandas as pd
import plotly.express as px
import uvicorn
from starlette.middleware.wsgi import WSGIMiddleware

def create_dash_app(prefix="/dash"):
    """
    Creates and configures a Dash app with an interactive Plotly scatter plot.
    
    Args:
        prefix (str): The URL prefix for the Dash app (e.g., "/dash").
    
    Returns:
        Dash: Configured Dash app instance.
    """
    # Initialize Dash app
    dash_app = Dash(__name__, requests_pathname_prefix=prefix)

    # Sample data and Plotly figure
    df = px.data.iris()  # Using iris dataset for demonstration
    fig = px.scatter(df, x="sepal_width", y="sepal_length", color="species", 
                     size="petal_length", hover_data=["petal_width"],
                     title="Interactive Iris Scatter Plot")

    # Dash layout
    dash_app.layout = html.Div([
        html.H1("Interactive Plotly Visualization"),
        dcc.Graph(id="scatter-plot", figure=fig),
        html.Label("Select Color Variable:"),
        dcc.Dropdown(
            id="color-dropdown",
            options=[
                {"label": "Species", "value": "species"},
                {"label": "Petal Length", "value": "petal_length"},
                {"label": "Petal Width", "value": "petal_width"}
            ],
            value="species",
            style={"width": "50%"}
        )
    ])

    # Callback for interactivity
    @dash_app.callback(
        Output("scatter-plot", "figure"),
        [Input("color-dropdown", "value")]
    )
    def update_graph(color_var):
        updated_fig = px.scatter(df, x="sepal_width", y="sepal_length", 
                                color=color_var, size="petal_length",
                                hover_data=["petal_width"],
                                title=f"Scatter Plot Colored by {color_var}")
        return updated_fig

    # Store the figure for JSON access
    dash_app.plotly_fig = fig  # Attach figure to app for external access

    return dash_app