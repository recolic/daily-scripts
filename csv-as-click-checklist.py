import sys
import os
import csv
import datetime
import tkinter as tk
from tkinter import ttk, messagebox

def print_usage_and_exit(error_msg=None):
    if error_msg:
        print(f"Error: {error_msg}\n")
    
    usage_text = """
======================================================================
                     Task Logger CLI Utility
======================================================================
Usage:
  python3 stamp_tool.py <path_to_csv_file>

Example:
  python3 stamp_tool.py prog.csv

Expected CSV Format (at least 1 column; timestamps will go into column 2):
  Column1 anything,time done
  d499a331-6be9-4e97-8129-07b94aca58f6,
  f24efd78-436c-441b-ba63-a21c85973bdd,2026-07-02 12:34:56

Note: If your file does not have a 2nd column yet, the tool will 
automatically format and align everything into a clean, 2-column CSV.
======================================================================
"""
    print(usage_text.strip())
    sys.exit(1)


class StampApp(tk.Tk):
    def __init__(self, csv_path):
        super().__init__()
        self.csv_path = csv_path
        self.title("Task Logger")
        self.geometry("700x450")
        
        self.headers = []
        self.rows = []
        
        self.load_data()
        self.create_widgets()
        
    def load_data(self):
        self.rows = []
        with open(self.csv_path, "r", newline="", encoding="utf-8") as f:
            reader = csv.reader(f)
            try:
                raw_headers = next(reader)
            except StopIteration:
                raw_headers = []
            
            # Guarantee exactly 2 column headers
            h0 = raw_headers[0].strip() if len(raw_headers) > 0 else "NodeId DZ5PrdApp74"
            h1 = raw_headers[1].strip() if len(raw_headers) > 1 else "time done"
            self.headers = [h0, h1]
                
            for row in reader:
                # Force every row to have exactly 2 columns, stripping extra whitespace
                node_id = row[0].strip() if len(row) > 0 else ""
                time_done = row[1].strip() if len(row) > 1 else ""
                self.rows.append([node_id, time_done])

    def save_data(self):
        with open(self.csv_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(self.headers)
            # This ensures only column 1 and column 2 are saved
            for row in self.rows:
                writer.writerow([row[0], row[1]])

    def create_widgets(self):
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("Treeview", rowheight=28, font=("Arial", 10))
        style.configure("Treeview.Heading", font=("Arial", 10, "bold"))
        
        lbl = ttk.Label(
            self, 
            text="💡 Click any row once to stamp current time. Click again to clear.", 
            font=("Arial", 10, "italic"), 
            padding=10
        )
        lbl.pack()

        frame = ttk.Frame(self)
        frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        scrollbar = ttk.Scrollbar(frame)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.tree = ttk.Treeview(
            frame, 
            columns=("node_id", "time_done"), 
            show="headings", 
            yscrollcommand=scrollbar.set
        )
        self.tree.heading("node_id", text=self.headers[0])
        self.tree.heading("time_done", text=self.headers[1])
        
        self.tree.column("node_id", width=420, anchor="w")
        self.tree.column("time_done", width=220, anchor="center")
        self.tree.pack(fill=tk.BOTH, expand=True)
        
        scrollbar.config(command=self.tree.yview)
        
        self.populate_tree()
        self.tree.bind("<ButtonRelease-1>", self.on_click)

        # Status Bar
        self.status_var = tk.StringVar()
        self.status_var.set(f"Loaded: {os.path.basename(self.csv_path)}")
        status_lbl = ttk.Label(self, textvariable=self.status_var, relief=tk.SUNKEN, anchor="w", padding=5)
        status_lbl.pack(fill=tk.X, side=tk.BOTTOM)

    def populate_tree(self):
        for item in self.tree.get_children():
            self.tree.delete(item)
        for i, row in enumerate(self.rows):
            self.tree.insert("", tk.END, iid=str(i), values=(row[0], row[1]))

    def on_click(self, event):
        region = self.tree.identify_region(event.x, event.y)
        if region not in ("tree", "cell"):
            return
        
        row_id = self.tree.identify_row(event.y)
        if row_id:
            idx = int(row_id)
            current_time_val = self.rows[idx][1]
            
            if not current_time_val:
                now_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                self.rows[idx][1] = now_str
                self.status_var.set(f"Stamped row {idx+1} at {now_str}")
            else:
                self.rows[idx][1] = ""
                self.status_var.set(f"Cleared stamp for row {idx+1}")
            
            self.save_data()
            self.populate_tree()
            self.tree.selection_set(row_id)


if __name__ == "__main__":
    # Check if correct arguments are provided
    if len(sys.argv) < 2:
        print_usage_and_exit("No CSV file specified.")
        
    target_file = sys.argv[1]
    
    if not os.path.exists(target_file):
        print_usage_and_exit(f"File '{target_file}' does not exist.")
        
    # Start the App
    app = StampApp(target_file)
    app.mainloop()

