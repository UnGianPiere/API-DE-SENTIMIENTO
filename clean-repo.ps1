$ErrorActionPreference = "Stop"

# Eliminar el archivo grande del historial de git
Write-Host "Limpiando el repositorio Git..."
git rm -r --cached .
git add .
git commit -m "Eliminar archivos grandes y reconfigurar .gitignore"

# Forzar la eliminación del archivo grande del historial
Write-Host "Forzando la eliminación de archivos grandes..."
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch app/modelo_roberta/model.safetensors" --prune-empty --tag-name-filter cat -- --all

# Limpiar y optimizar el repositorio
Write-Host "Limpiando y optimizando el repositorio..."
git for-each-ref --format="%(refname)" refs/original/ | ForEach-Object { git update-ref -d $_ }
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Actualizar el repositorio remoto
Write-Host "Actualizando el repositorio remoto..."
git push origin --force --all

Write-Host "¡Listo! El repositorio ha sido limpiado y actualizado."
