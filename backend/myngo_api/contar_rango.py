with open('d:/TFG/myngo/frontend/myngo_app/lib/screens/perfiles/pantalla_tienda_mejoras.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

content = "".join(lines[31:593]) # Lines 32 to 593
open_braces = content.count('{')
close_braces = content.count('}')

print(f"Range 32-593: {{: {open_braces}, }}: {close_braces}, Diff: {open_braces - close_braces}")
