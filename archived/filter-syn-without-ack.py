# use filter tcp.flags.syn == 1, export packet dissections as csv
import csv

def filter_unsynacks(input_csv):
    syn_packets = []
    synacks = set()

    with open(input_csv, 'r') as infile:
        reader = csv.reader(infile)
        
        for row in reader:
            description = row[-1]
            if '[SYN' in description:
                src_port = description.split('>')[0].strip().split()[-1]
                dst_port = description.split('>')[1].strip().split()[0]
                if 'ACK]' in description:
                    synacks.add((src_port, dst_port))

    with open(input_csv, 'r') as infile:
        reader = csv.reader(infile)
        
        for row in reader:
            description = row[-1]
            if '[SYN' in description:
                src_port = description.split('>')[0].strip().split()[-1]
                dst_port = description.split('>')[1].strip().split()[0]
                if (src_port, dst_port) not in synacks and (dst_port, src_port) not in synacks:
                    print(row)


# Example usage
input_csv = '3l2exp2.csv'
filter_unsynacks(input_csv)

