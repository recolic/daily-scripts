import pandas as pd
import matplotlib.pyplot as plt
import sys

twindow = '2H'
twindow = '1H'

# Read data from CSV file
df = pd.read_csv(sys.argv[1])

# Parse datetime using DATE and START TIME
start_dt = pd.to_datetime(df['DATE'] + ' ' + df['START TIME'])
df['start_dt'] = start_dt

# Set datetime as index for rolling operation
df.set_index('start_dt', inplace=True)

# Rolling average with 2h window centered
rolling = df['USAGE (kWh)'].rolling(twindow, center=True).mean()

# Plot
plt.figure(figsize=(10, 5))
plt.plot(df.index, rolling, label='Smoothed Usage ('+twindow+' window)')
plt.xlabel('Time')
plt.ylabel('Electricity Usage (kWh)')
plt.title('Electricity Usage Over Time (Smoothed)')
plt.grid(True)
plt.legend()
plt.tight_layout()
plt.show()

