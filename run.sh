# 1) 先把所有 submodules 抓齊
git submodule update --init --recursive

# 2) （可選）吸收 submodule 的 gitdir，避免奇怪狀態
git submodule absorbgitdirs || true

# 3) 逐一把 submodule 變成一般目錄（不刪實體檔案）
for p in libjpeg-turbo libvncserver noVNC; do
  # 從 index 移除「gitlink」，但保留工作目錄內容
  git rm --cached "$p"
  # 刪掉 superproject 裡面對應的 git 內部資料夾
  rm -rf ".git/modules/$p"
  # 將該目錄當作一般檔案加入版本控制
  git add "$p"
done

# 4) 移除 .gitmodules 中對應段落
git config -f .gitmodules --remove-section submodule.libjpeg-turbo || true
git config -f .gitmodules --remove-section submodule.libvncserver || true
git config -f .gitmodules --remove-section submodule.noVNC || true

# 若 .gitmodules 已空，順便從版控移除它
[ -s .gitmodules ] || git rm -f .gitmodules || true

# 5) 提交
git commit -m "Vendor submodules: libjpeg-turbo, libvncserver, noVNC (de-submodule)"
