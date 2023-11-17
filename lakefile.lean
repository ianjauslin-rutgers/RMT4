import Lake
open Lake DSL

package «rMT4» {
  -- add any package configuration options here
}

require mathlib from git "https://github.com/leanprover-community/mathlib4.git"@"11572f182a36a4441f9a62246985ed9d2e1f3e32"

require «doc-gen4» from git "https://github.com/leanprover/doc-gen4"@"main"

@[default_target]
lean_lib RMT4 {
  -- add any library configuration options here
}
