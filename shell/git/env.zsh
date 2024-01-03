case $(_os) in
    linux-*)
        export GCM_CREDENTIAL_STORE=gpg
        ;;
    macos)
        export GCM_CREDENTIAL_STORE=keychain
        ;;
esac
