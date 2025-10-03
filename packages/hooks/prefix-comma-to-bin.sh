prefixCommaToBin() {
    if [[ -d "${out:?}/bin" ]]
    then
        for f in "${out:?}/bin"/*
        do
            new_name=",$(basename "$f")"
            command mv -v "$f" "${out:?}/bin/$new_name"
        done
    fi
}

postInstallHooks+=('prefixCommaToBin')
