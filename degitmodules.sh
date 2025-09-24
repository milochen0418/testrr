#!/bin/sh
set -e

COMMIT_MSG="Vendor submodules (auto de-submodule from .gitmodules)"

if [ ! -f .gitmodules ]; then
  echo "[INFO] No .gitmodules found. Nothing to do."
  exit 0
fi

echo "[STEP] git submodule update --init --recursive"
git submodule update --init --recursive

echo "[STEP] git submodule absorbgitdirs (best-effort)"
if git submodule absorbgitdirs >/dev/null 2>&1; then :; else
  echo "[WARN] 'git submodule absorbgitdirs' not available. Continue."
fi

# 取得所有 submodule 的 section 名稱（例如 submodule.libjpeg-turbo）
SECTIONS="$(git config -f .gitmodules --name-only --get-regexp '^submodule\..*\.path$' 2>/dev/null | sed 's/\.path$//')"

if [ -z "$SECTIONS" ]; then
  echo "[INFO] No submodule sections found in .gitmodules. Nothing to do."
  exit 0
fi

echo "[INFO] Found submodules:"
echo "$SECTIONS" | sed 's/^/  - /'

echo "$SECTIONS" | while IFS= read -r section; do
  [ -z "$section" ] && continue
  path="$(git config -f .gitmodules --get "${section}.path")"
  echo "[STEP] De-submodule: section='${section}' path='${path}'"

  if [ ! -d "$path" ]; then
    echo "  [WARN] Worktree path not found: ${path} (skip)"
    continue
  fi

  # 1) 從 index 移除 gitlink（不刪實體檔）
  echo "  - git rm --cached '${path}'"
  git rm --cached -q "$path" || true

  # 2) 刪 superproject 的 modules 資料夾
  echo "  - rm -rf '.git/modules/${path}'"
  rm -rf ".git/modules/${path}"

  # 3) 刪掉該子樹下所有 .git（避免 nested submodules 殘留）
  #    同時移除子樹內的 .gitmodules（若存在）
  echo "  - purge '${path}/.git' and nested .git/.gitmodules"
  find "$path" -name .git -exec rm -rf {} + 2>/dev/null || true
  find "$path" -name .gitmodules -exec rm -f {} + 2>/dev/null || true

  # 4) 轉為一般追蹤檔案
  echo "  - git add '${path}'"
  git add -A "$path"

  # 5) 從 .gitmodules 移除段落，並立刻把 .gitmodules 加到暫存（避免下一輪報錯）
  echo "  - remove section '${section}' from .gitmodules & stage it"
  git config -f .gitmodules --remove-section "$section" || true
  if [ -f .gitmodules ]; then
    git add .gitmodules || true
  fi
done

# 6) 若 .gitmodules 已空，移除；否則保持已 staged
if [ ! -s .gitmodules ]; then
  echo "[STEP] .gitmodules is empty -> git rm -f .gitmodules"
  git rm -f .gitmodules || true
fi

echo "[STEP] git commit"
git commit -m "$COMMIT_MSG" || true

echo "[DONE] De-submodule complete."
