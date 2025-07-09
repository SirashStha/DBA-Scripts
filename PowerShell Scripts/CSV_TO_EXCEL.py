import pandas as pd
import os

# Define source and destination folders
source_folder = 'D:/1 Imp Scripts/Power Shell Scripts/path/DT/'
destination_folder = 'D:/1 Imp Scripts/Power Shell Scripts/path/to/'

# Create destination folder if it doesn't exist
os.makedirs(destination_folder, exist_ok=True)

# Convert each CSV file to Excel with enhancements
for file_name in os.listdir(source_folder):
    if file_name.endswith('.csv'):
        csv_path = os.path.join(source_folder, file_name)
        excel_path = os.path.join(destination_folder, file_name.replace('.csv', '.xlsx'))

        df = pd.read_csv(csv_path)

        # Skip empty files
        if df.empty:
            print(f"Skipped empty file: {file_name}")
            continue

        # Ensure the 'DATE' column is in the correct format
        if 'DATE' in df.columns:
            # Convert 'DATE' to datetime and format as 'YYYY-MM-DD'
            df['DATE'] = pd.to_datetime(df['DATE'], errors='coerce').dt.strftime('%Y-%m-%d')

            # Sort by 'DATE'
            df.sort_values('DATE', inplace=True)

            # Insert empty rows after date changes
            new_rows = []
            prev_date = None

            for index, row in df.iterrows():
                current_date = row['DATE']
                if prev_date and current_date != prev_date:
                    # Add an empty row with blank values
                    new_rows.append(pd.Series({col: '' for col in df.columns}))
                new_rows.append(row)
                prev_date = current_date

            # Convert the list back to a DataFrame
            df = pd.DataFrame(new_rows)

        # Write to Excel with proper formatting
        with pd.ExcelWriter(excel_path, engine='xlsxwriter') as writer:
            df.to_excel(writer, index=False, sheet_name='Sheet1')

            # Apply filters and column formatting
            workbook = writer.book
            worksheet = writer.sheets['Sheet1']

            # Apply autofilter to all columns
            worksheet.autofilter(0, 0, df.shape[0], df.shape[1] - 1)

            # Format the 'DATE' column to display only the date
            date_format = workbook.add_format({'num_format': 'yyyy-mm-dd'})
            if 'DATE' in df.columns:
                col_index = df.columns.get_loc('DATE')
                worksheet.set_column(col_index, col_index, 15, date_format)

        print(f"Successfully converted: {file_name} to {excel_path}")

print("All conversions completed.")
