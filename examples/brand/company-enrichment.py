import csv
import sys
import requests

domains = sys.argv[1:] or ["github.com", "stripe.com"]
writer = csv.writer(sys.stdout)
writer.writerow(["domain", "status", "brand_json"])
for domain in domains:
    response = requests.get(f"https://brand.replynodes.com/{domain}", timeout=20)
    response.raise_for_status()
    writer.writerow([domain, response.status_code, response.text])
