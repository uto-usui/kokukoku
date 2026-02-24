SHELL := /bin/zsh

.PHONY: bootstrap doctor open-xcode open-cursor

bootstrap:
	./scripts/bootstrap_macos.sh

doctor:
	./scripts/doctor.sh

open-xcode:
	open -a Xcode .

open-cursor:
	cursor .
