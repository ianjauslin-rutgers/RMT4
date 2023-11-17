build: update cache
	lake build

update: toolchain
	lake update

cache: toolchain
	lake exe cache get

toolchain:
	-cp -f lake-packages/mathlib/lean-toolchain ./

doc:
	-lake build RMT4:docs
	lake exe doc-gen4 index

blueprint: doc
	make -C blueprint
	make -C blueprint clean-aux

clean-doc:
	rm -rf build/doc/*

clean-packages:
	rm -rf lake-packages/*
