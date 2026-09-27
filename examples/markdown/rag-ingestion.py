"""Fetch Markdown for a RAG loader; keep HTTP failures visible to the job."""
import sys
import requests

source = sys.argv[1] if len(sys.argv) > 1 else "https://example.com/"
path = source.removeprefix("https://").removeprefix("http://")
response = requests.get(f"https://md.replynodes.com/{path}", timeout=30)
response.raise_for_status()
document = {"source": source, "text": response.text, "content_type": response.headers.get("content-type")}
print(document)
