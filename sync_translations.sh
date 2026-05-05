#!/bin/bash
set -e
echo "Pulling translations from Tolgee..."
cd frontend/myngo_app && tolgee pull && flutter gen-l10n
cd ../backend/myngo_api && tolgee pull && python manage.py compilemessages
echo "Done."
