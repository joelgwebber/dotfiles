function load-secrets --description 'Load ~/.s3kr1tz.sh (POSIX export syntax) into fish'
    set -l file ~/.s3kr1tz.sh
    test -f $file; or return 0

    # The file stays POSIX so zsh can still source it directly and so any
    # bash/zsh tooling that reads it keeps working. fish can't source it, so we
    # parse the `export K="V"` lines instead. Commented lines start with # and
    # therefore never match.
    while read -l line
        set line (string trim -- $line)
        string match -qr '^export\s+[A-Za-z_][A-Za-z0-9_]*=' -- $line; or continue

        set -l kv (string split -m1 '=' -- (string replace -r '^export\s+' '' -- $line))
        test (count $kv) -eq 2; or continue

        # strip one layer of surrounding single or double quotes
        set -l val (string replace -r '^(["\'])(.*)\1$' '$2' -- $kv[2])
        set -gx $kv[1] $val
    end <$file
end
