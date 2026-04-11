#!/usr/bin/env python3
"""
BeWell — Verifica traduzioni
Esegui prima di ogni build per trovare chiavi mancanti.

Uso: python scripts/check_translations.py
"""

import re
import sys
from pathlib import Path

LOCALIZATIONS_FILE = Path("lib/l10n/app_localizations.dart")
LANGUAGES = ['en', 'it', 'fr', 'de', 'es']
LANG_CLASSES = {'en': '_En', 'it': '_It', 'fr': '_Fr', 'de': '_De', 'es': '_Es'}

def extract_abstract_keys(content: str) -> list[str]:
    """Estrae tutte le chiavi dall'abstract class BwStrings."""
    # Trova il blocco abstract
    abstract_match = re.search(
        r'abstract class BwStrings \{(.+?)^}',
        content, re.DOTALL | re.MULTILINE
    )
    if not abstract_match:
        print("❌ Non trovo 'abstract class BwStrings'")
        sys.exit(1)
    
    abstract_body = abstract_match.group(1)
    keys = re.findall(r'String get (\w+);', abstract_body)
    return keys

def extract_class_keys(content: str, class_name: str) -> set[str]:
    """Estrae le chiavi implementate in una classe concreta."""
    # Trova il blocco della classe
    pattern = rf'class {re.escape(class_name)} extends BwStrings \{{(.+?)^}}'
    match = re.search(pattern, content, re.DOTALL | re.MULTILINE)
    if not match:
        return set()
    
    body = match.group(1)
    keys = re.findall(r'String get (\w+) =>', body)
    return set(keys)

def main():
    if not LOCALIZATIONS_FILE.exists():
        print(f"❌ File non trovato: {LOCALIZATIONS_FILE}")
        sys.exit(1)
    
    content = LOCALIZATIONS_FILE.read_text(encoding='utf-8')
    
    # Estrai chiavi abstract
    abstract_keys = extract_abstract_keys(content)
    print(f"📋 Chiavi totali in BwStrings: {len(abstract_keys)}")
    
    errors = []
    warnings = []
    
    for lang, class_name in LANG_CLASSES.items():
        implemented = extract_class_keys(content, class_name)
        
        if not implemented:
            errors.append(f"❌ Classe {class_name} ({lang}) non trovata!")
            continue
        
        missing = [k for k in abstract_keys if k not in implemented]
        extra = [k for k in implemented if k not in abstract_keys]
        
        if missing:
            errors.append(f"\n🔴 [{lang}] {len(missing)} chiavi MANCANTI:")
            for key in missing:
                errors.append(f"   - {key}")
        
        if extra:
            warnings.append(f"\n⚠️  [{lang}] {len(extra)} chiavi EXTRA (non nell'abstract):")
            for key in extra:
                warnings.append(f"   - {key}")
        
        if not missing and not extra:
            print(f"✅ [{lang}] {class_name} — {len(implemented)} chiavi OK")
    
    if warnings:
        print("\n" + "\n".join(warnings))
    
    if errors:
        print("\n" + "\n".join(errors))
        print(f"\n❌ Trovati problemi — correggi prima di buildare")
        sys.exit(1)
    else:
        print("\n✅ Tutte le traduzioni sono complete!")
        sys.exit(0)

if __name__ == "__main__":
    main()
