#!/usr/bin/env python3
# GPT 5.6 sol
import html
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

IMAGE_RE = re.compile(r"(!\[[^]]*\]\()([^\s)]+)([^)]*\))|(<img\b[^>]*?\bsrc=[\"'])([^\"']+)([\"'][^>]*>)", re.IGNORECASE)


def request(url, gitlab_token, binary=False):
    headers = {"User-Agent": "gitlab-issue-to-pdf/1"}
    if gitlab_token:
        headers["PRIVATE-TOKEN"] = gitlab_token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers)) as response:
        data = response.read()
        return (data if binary else json.loads(data)), response.headers


def api_pages(url, gitlab_token):
    result = []
    page = 1
    while page:
        separator = "&" if "?" in url else "?"
        data, headers = request(f"{url}{separator}per_page=100&page={page}", gitlab_token)
        result.extend(data)
        page = int(headers.get("X-Next-Page") or 0)
    return result


def download_images(markdown, project_url, project_api, image_dir, gitlab_token, image_number):
    def replace(match):
        nonlocal image_number
        url = html.unescape(match.group(2) or match.group(5))
        if url.startswith("data:"):
            return match.group(0)
        absolute_url = project_api + url if url.startswith("/uploads/") else urllib.parse.urljoin(project_url + "/", url)
        download_token = gitlab_token if urllib.parse.urlparse(absolute_url).netloc == urllib.parse.urlparse(project_url).netloc else ""
        try:
            data, headers = request(absolute_url, download_token, binary=True)
        except (OSError, urllib.error.HTTPError) as error:
            print(f"warning: could not download {absolute_url}: {error}", file=sys.stderr)
            return match.group(0)
        extension = Path(urllib.parse.urlparse(absolute_url).path).suffix
        if not extension or len(extension) > 8:
            extension = mimetypes.guess_extension(headers.get_content_type()) or ".img"
        image_number += 1
        path = image_dir / f"image-{image_number}{extension}"
        path.write_bytes(data)
        local_url = path.as_uri()
        if match.group(2):
            return f"{match.group(1)}{local_url}{match.group(3)}"
        return f"{match.group(4)}{local_url}{match.group(6)}"

    return IMAGE_RE.sub(replace, markdown or ""), image_number


def main():
    name = Path(sys.argv[0]).name
    help_message = f"usage: {name} ISSUE_URL [OUTPUT.pdf]\nexample: env GITLAB_TOKEN=(rsec GITLAB_API_READ) ./{name} 'https://git.recolic.net/root/recolic-board/-/issues/377' /tmp/issue-377.pdf"
    gitlab_token = os.environ.get("GITLAB_TOKEN")
    if len(sys.argv) not in (2, 3) or not gitlab_token:
        sys.exit(help_message)
    issue_url = sys.argv[1].rstrip("/")
    match = re.fullmatch(r"(https?://[^/]+)/(.+)/-/issues/(\d+)", issue_url)
    if not match:
        sys.exit("error: expected a GitLab URL ending in /-/issues/NUMBER")
    site, project, iid = match.groups()
    output = Path(sys.argv[2] if len(sys.argv) == 3 else f"gitlab-issue-{iid}.pdf").expanduser().resolve()
    project_url = f"{site}/{project}"
    project_api = f"{site}/api/v4/projects/{urllib.parse.quote(project, safe='')}"
    api = f"{project_api}/issues/{iid}"
    try:
        issue, _ = request(api, gitlab_token)
        discussions = api_pages(f"{api}/discussions", gitlab_token)
    except urllib.error.HTTPError as error:
        sys.exit(f"error: GitLab API returned HTTP {error.code}")
    cmark = shutil.which("cmark") or shutil.which("cmark-gfm")
    wkhtmltopdf = shutil.which("wkhtmltopdf")
    chromium = next((shutil.which(name) for name in ("chromium", "chromium-browser", "google-chrome") if shutil.which(name)), None)
    if not cmark or not (wkhtmltopdf or chromium):
        sys.exit("error: cmark and either wkhtmltopdf or chromium are required")
    with tempfile.TemporaryDirectory(prefix="gitlab-issue-", dir="/tmp") as temp_name:
        temp = Path(temp_name)
        image_dir = temp / "images"
        image_dir.mkdir()
        image_number = 0
        description, image_number = download_images(issue.get("description", ""), project_url, project_api, image_dir, gitlab_token, image_number)
        author = issue.get("author") or {}
        lines = [f"# {issue['title']}", "", f"{author.get('name') or author.get('username') or 'Unknown'} at {issue.get('created_at', 'unknown time')}:", "", description or "*(no description)*", "", "# Discussion", ""]
        for discussion in discussions:
            for note in discussion.get("notes", []):
                body, image_number = download_images(note.get("body", ""), project_url, project_api, image_dir, gitlab_token, image_number)
                note_author = note.get("author") or {}
                lines.extend([f"## {note_author.get('name') or note_author.get('username') or 'Unknown'} at {note.get('created_at', 'unknown time')}", "", body or "*(empty)*", ""])
        markdown_path = temp / "issue.md"
        markdown_path.write_text("\n".join(lines), encoding="utf-8")
        html_path = temp / "issue.html"
        try:
            with html_path.open("w", encoding="utf-8") as html_file:
                subprocess.run([cmark, "--unsafe", str(markdown_path)], check=True, stdout=html_file)
            if wkhtmltopdf:
                subprocess.run([wkhtmltopdf, "--enable-local-file-access", str(html_path), str(output)], check=True)
            else:
                subprocess.run([chromium, "--headless", "--disable-gpu", "--no-pdf-header-footer", "--allow-file-access-from-files", f"--print-to-pdf={output}", html_path.as_uri()], check=True)
        except subprocess.CalledProcessError as error:
            sys.exit(f"error: PDF conversion failed with exit code {error.returncode}")
    print(output)


if __name__ == "__main__":
    main()
