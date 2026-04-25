with open('d:/TFG/myngo/frontend/myngo_app/lib/screens/perfiles/pantalla_tienda_mejoras.dart', 'r', encoding='utf-8') as f:
    content = f.read()

open_braces = content.count('{')
close_braces = content.count('}')
open_parens = content.count('(')
close_parens = content.count(')')

print(f"Braces: {{: {open_braces}, }}: {close_braces}, Diff: {open_braces - close_braces}")
print(f"Parens: (: {open_parens}, ): {close_parens}, Diff: {open_parens - close_parens}")
