import pandas as pd
import sqlite3

paths = [r'CovidDeaths.xlsx', r'CovidVaccinations.xlsx']
tables = ['Deaths', 'Vaccinations']
db = sqlite3.connect('COVID.db')

for table, path in zip(tables, paths):
    df = pd.read_excel(path, sheet_name=None)
    df['Covid'+table].to_sql(table, db)