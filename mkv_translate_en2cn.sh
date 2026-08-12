#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 input.mkv" >&2
    exit 2
fi

input=$1
[[ -f "$input" ]] || { echo "Input does not exist: $input" >&2; exit 1; }
for cmd in mkvmerge mkvextract python3 gpt.py; do
    command -v "$cmd" >/dev/null || { echo "Missing command: $cmd" >&2; exit 1; }
done

fname=${input%.*}
source_srt="$fname.tmp_srt"
converted_srt="$source_srt.converted"
output_mkv="$fname.en-cn.mkv"
helper="$source_srt.helper.py"
chunk_cues=${CHUNK_CUES:-100}
max_retries=${MAX_RETRIES:-16}

read -r subtitle_id max_track_id < <(mkvmerge --identification-format json --identify "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); t=d["tracks"]; s=[x["id"] for x in t if x["type"]=="subtitles"]; print(s[0] if s else -1, max(x["id"] for x in t))')
((subtitle_id >= 0)) || { echo "No subtitle track found in: $input" >&2; exit 1; }
expected_new_track_id=$((max_track_id + 1))
echo "Extracting subtitle track $subtitle_id -> $source_srt"
mkvextract tracks "$input" "$subtitle_id:$source_srt"

cat > "$helper" <<'PY'
#!/usr/bin/env python3
import pathlib, re, sys

def read_cues(path):
    text = pathlib.Path(path).read_text(encoding="utf-8-sig").replace("\r\n", "\n").replace("\r", "\n").strip()
    cues = re.split(r"\n[ \t]*\n", text) if text else []
    for cue in cues:
        lines = cue.splitlines()
        if len(lines) < 3 or "-->" not in lines[1]:
            raise ValueError(f"invalid SRT cue: {cue[:100]!r}")
    return cues

def clean_response(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n").strip()
    match = re.fullmatch(r"```(?:srt)?\s*\n(.*?)\n```", text, re.DOTALL | re.IGNORECASE)
    return match.group(1).strip() if match else text

def validate(source_path, candidate_path, output_path=None):
    source = read_cues(source_path)
    candidate_text = clean_response(pathlib.Path(candidate_path).read_text(encoding="utf-8-sig"))
    candidate_tmp = pathlib.Path(candidate_path).with_name(pathlib.Path(candidate_path).name + ".validate_tmp")
    candidate_tmp.write_text(candidate_text + "\n", encoding="utf-8")
    try:
        candidate = read_cues(candidate_tmp)
    finally:
        candidate_tmp.unlink(missing_ok=True)
    if len(source) != len(candidate):
        raise ValueError(f"cue count changed: expected {len(source)}, got {len(candidate)}")
    for number, (old, new) in enumerate(zip(source, candidate), 1):
        old_lines, new_lines = old.splitlines(), new.splitlines()
        if old_lines[:2] != new_lines[:2]:
            raise ValueError(f"cue {number} index or timestamp changed")
        if not "\n".join(new_lines[2:]).strip():
            raise ValueError(f"cue {number} has empty subtitle text")
    old_text = "\n".join("\n".join(c.splitlines()[2:]) for c in source)
    new_text = "\n".join("\n".join(c.splitlines()[2:]) for c in candidate)
    if re.search(r"[A-Za-z]{3}", old_text) and not re.search(r"[\u3400-\u9fff]", new_text):
        raise ValueError("translated chunk contains no Chinese characters")
    if output_path:
        pathlib.Path(output_path).write_text(candidate_text + "\n", encoding="utf-8")

def main():
    mode = sys.argv[1]
    if mode == "split":
        source, prefix, size = sys.argv[2], sys.argv[3], int(sys.argv[4])
        cues = read_cues(source)
        chunks = [cues[i:i + size] for i in range(0, len(cues), size)]
        for number, chunk in enumerate(chunks, 1):
            pathlib.Path(f"{prefix}.{number}.source").write_text("\n\n".join(chunk) + "\n", encoding="utf-8")
        print(len(chunks))
    elif mode == "prompt":
        source, output = sys.argv[2], sys.argv[3]
        srt = pathlib.Path(source).read_text(encoding="utf-8")
        prompt = """Translate the following English SRT subtitle chunk into natural Simplified Chinese. Use the surrounding cues as context. Return only valid SRT, with exactly the same cue numbers, timestamps, cue count, blank-line separation, line-break structure, and formatting tags. Translate only subtitle text. Do not add Markdown fences, comments, explanations, or extra cues.\n\n"""
        pathlib.Path(output).write_text(prompt + srt, encoding="utf-8")
    elif mode == "validate":
        validate(*sys.argv[2:])
    elif mode == "assemble":
        output, *parts = sys.argv[2:]
        text = "\n".join(pathlib.Path(part).read_text(encoding="utf-8").strip() for part in parts) + "\n"
        pathlib.Path(output).write_text(text, encoding="utf-8")
        read_cues(output)
    else:
        raise ValueError(f"unknown mode: {mode}")

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(error, file=sys.stderr)
        sys.exit(1)
PY

chunk_prefix="$source_srt.chunk"
chunk_count=$(python3 "$helper" split "$source_srt" "$chunk_prefix" "$chunk_cues")
((chunk_count > 0)) || { echo "Extracted subtitle has no cues" >&2; exit 1; }
translated_parts=()
for ((chunk = 1; chunk <= chunk_count; chunk++)); do
    source_chunk="$chunk_prefix.$chunk.source"
    prompt_file="$chunk_prefix.$chunk.prompt"
    translated_file="$chunk_prefix.$chunk.translated"
    translated_parts+=("$translated_file")
    python3 "$helper" prompt "$source_chunk" "$prompt_file"
    if [[ -s "$translated_file" ]] && python3 "$helper" validate "$source_chunk" "$translated_file"; then
        echo "[$chunk/$chunk_count] Reusing validated translation"
        continue
    fi
    valid=false
    for ((attempt = 1; attempt <= max_retries; attempt++)); do
        raw_file="$chunk_prefix.$chunk.attempt$attempt.raw"
        echo "[$chunk/$chunk_count] Translating, attempt $attempt/$max_retries"
        if gpt.py grokr "$prompt_file" > "$raw_file" && python3 "$helper" validate "$source_chunk" "$raw_file" "$translated_file"; then
            valid=true
            break
        fi
        echo "[$chunk/$chunk_count] Invalid output; retrying" >&2
    done
    [[ "$valid" == true ]] || { echo "Translation failed after $max_retries attempts for chunk $chunk" >&2; exit 1; }
done

python3 "$helper" assemble "$converted_srt" "${translated_parts[@]}"
echo "Validated translated subtitle -> $converted_srt"
echo "Merging as subtitle track $expected_new_track_id -> $output_mkv"
mkvmerge -o "$output_mkv" "$input" --language 0:zh-Hans --track-name 0:"Simplified Chinese (GPT)" --default-track-flag 0:no "$converted_srt"
actual_new_track_id=$(mkvmerge --identification-format json --identify "$output_mkv" | python3 -c 'import json,sys; t=json.load(sys.stdin)["tracks"]; print(max(x["id"] for x in t))')
[[ "$actual_new_track_id" -eq "$expected_new_track_id" ]] || { echo "Unexpected new track ID: expected $expected_new_track_id, got $actual_new_track_id" >&2; exit 1; }
echo "Done: $output_mkv (new subtitle track ID $actual_new_track_id)"
echo "Temporary files were kept with prefix: $source_srt"
