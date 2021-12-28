if _is_callable clang-format; then
  # alias format-all-clang="find . -regex '.*\.\(cpp\|hpp\|cc\|cxx\|h\)' -exec clang-format -style=file -i {} \;"
  alias format-all-clang="fd -x clang-format -i -style=file {} \; -e c -e cc -e cpp -e h -e hh -e hpp ."
fi

function cmake-pre-build () {
  cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=YES -S . -B build
  ln -s -f build/compile_commands.json
}
function cmake-build-all() {
  cmake --build build --config Debug --target all -j 14 --
}
