function load-work-env --description 'Import the FullStory bash env (~/.fsprofile) into fish'
    test -f ~/.fsprofile; or return 0

    # ~/.fsprofile is '### DO NOT EDIT ###' FullStory-managed bash, and it
    # sources $FSDEV_HOME/environment.inc, also bash. fish can't source either,
    # so run them in bash and import the resulting environment.
    #
    # Deliberately NOT imported: PATH and shell internals. environment.inc does
    # not touch PATH (checked), and letting bash's PATH overwrite fish's would
    # undo everything conf.d/00-path.fish just did.
    set -l skip PATH SHELL SHLVL PWD OLDPWD _ IFS BASH BASH_VERSION BASH_EXECUTION_STRING

    for line in (bash -c 'source ~/.fsprofile >/dev/null 2>&1; env' 2>/dev/null)
        set -l kv (string split -m1 '=' -- $line)
        test (count $kv) -eq 2; or continue
        contains -- $kv[1] $skip; and continue
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $kv[1]; or continue
        set -gx $kv[1] $kv[2]
    end
end
