encoded = "慣慤敭祻ㄶ形楴獟楮獴㌴摟潦弸強㤰扡㌷敽"
decoded = ""

for char in encoded:
    num = ord(char)

    a = num >> 8
    b = num & 255

    decoded += chr(a)
    decoded += chr(b)

print(decoded)
