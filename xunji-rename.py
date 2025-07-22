import os
import re
import argparse

def gen_vid(basename: str) -> str:
    vid = ""

    # Find date: 6 consecutive digits
    m_date = re.search(r'(\d{6})', basename)
    vid += f"D{m_date.group(1)}" if m_date else ""

    # Find "第xxx期"
    m_epi = re.search(r'第(\d+)期', basename)
    vid += f"E{int(m_epi.group(1)):03d}" if m_epi else ""

    return vid if vid else "N"

def rename_filename(filename: str) -> str:
    basename = os.path.basename(filename)
    prefix = gen_vid(basename)
    new_basename = f"{prefix}.{basename}" if prefix else basename
    return os.path.join(os.path.dirname(filename), new_basename) if os.path.dirname(filename) else new_basename

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--rename', action='store_true', help='Actually rename files (default is dry run)')
    args = parser.parse_args()

    for fname in os.listdir('.'):
        if not os.path.isfile(fname):
            continue
        newname = rename_filename(fname)
        if newname != fname:
            print(f"rename {newname}    <<==    {fname}")
            if args.rename:
                os.rename(fname, newname)

if __name__ == '__main__':
    main()

