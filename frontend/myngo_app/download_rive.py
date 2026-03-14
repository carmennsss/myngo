import urllib.request
import ssl

url = "https://public.rive.app/community/runtime-files/3645-7621-animated-login-screen.riv"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
context = ssl._create_unverified_context()
with urllib.request.urlopen(req, context=context) as response, open('assets/animated_login_character.riv', 'wb') as out_file:
    data = response.read()
    out_file.write(data)
print("File downloaded successfully")
