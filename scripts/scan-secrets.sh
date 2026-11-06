#!/usr/bin/env bash
# Scan the repo for committed secrets. Prints file paths only — never the secret.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

# Skip lockfiles, binary-ish trees, and local build output.
excludes=(
  --glob '!.git/**'
  --glob '!**/node_modules/**'
  --glob '!**/.build/**'
  --glob '!**/DerivedData/**'
  --glob '!**/*.png'
  --glob '!**/*.jpg'
  --glob '!**/*.pdf'
  --glob '!**/*.zip'
)

patterns=(
  'BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY'
  'AKIA[0-9A-Z]{16}'
  'sk_live_[0-9a-zA-Z]{20,}'
  'sk_test_[0-9a-zA-Z]{20,}'
  'service_role=.+'
  'SUPABASE_JWT_SECRET=[A-Za-z0-9+/=_-]{20,}'
  'SUPABASE_SERVICE_ROLE=.+'
  'ghp_[0-9A-Za-z]{20,}'
  'github_pat_[0-9A-Za-z_]{20,}'
  'xox[baprs]-'
  '-----BEGIN CERTIFICATE-----'
)

found=0
for pattern in "${patterns[@]}"; do
  matches="$(rg -l -I --hidden "${excludes[@]}" -e "$pattern" . 2>/dev/null || true)"
  if [[ -n "$matches" ]]; then
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      # .env.example mentions the names on purpose; that is not a leaked value.
      if [[ "$file" == *".env.example" ]]; then
        continue
      fi
      if [[ "$file" == *"scan-secrets.sh" ]]; then
        continue
      fi
      echo "possible secret pattern in $file"
      found=1
    done <<< "$matches"
  fi
done

if [[ "$found" -eq 0 ]]; then
  echo "scan-secrets: no committed secret patterns found"
  exit 0
fi

echo "scan-secrets: review the files above. If a real key is in git, rotate it and stop committing it."
exit 1
