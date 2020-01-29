from PIL import Image
from pprint import pprint
"""
assembly file has rto be written this way:

myVar: .db 0x0000

"""




if __name__ == "__main__":
    output = """
.cseg
"""

    image = Image.open("../assets/font.png")
    
    # -- numbers
    y_offset = 8
    x_offset = 0
    length = 10

    chars_bytes = []

    for i in range(0,length):
        one_char_bytes = []
        for y in range(y_offset, y_offset+8):
            line = []
            for x in range(i*8, (i+1)*8):
                pixel = image.getpixel((x,y))
                line.append(str(pixel))
            line = "0b"+"".join(line)
            one_char_bytes.append(line)
        #pprint(one_char_bytes)
        chars_bytes.append(one_char_bytes)
            
    for i in range(10):
        output += "char_%s: .db " % i
        output += ", \\\n            ".join(chars_bytes[i])
        output += "\n"

    print(output)
