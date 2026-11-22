import urllib.request, re, os

req = urllib.request.Request('https://github.com/gggddvdgdh-cell/VN-Sign/releases', headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as resp:
    html = resp.read().decode('utf-8', errors='ignore')

releases = re.findall(r'/gggddvdgdh-cell/VN-Sign/releases/tag/([^"]+)', html)
print('Found tags:', releases[:5])

downloads = re.findall(r'/gggddvdgdh-cell/VN-Sign/releases/download/[^"]+\.ipa', html)
print('Found IPA downloads:', downloads)

if downloads:
    dl_url = 'https://github.com' + downloads[0]
    out_file = r'd:\VN-Sign\VN-Sign.ipa'
    if os.path.exists(out_file):
        os.remove(out_file)
    print('Downloading latest VN-Sign.ipa from:', dl_url)
    urllib.request.urlretrieve(dl_url, out_file)
    print('Downloaded successfully! File size:', os.path.getsize(out_file), 'bytes')
else:
    # Check workflow artifacts if release wasn't tagged
    print('No direct release download link found on releases main page.')
