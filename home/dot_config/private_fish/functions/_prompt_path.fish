function _prompt_path --description 'zsh %(4~|.../%3~|%~): last 3 components, elided with ...'
    # fish's prompt_pwd can't do this: --dir-length=0 prints the path in full
    # rather than eliding the head, so the zsh behaviour is reimplemented here.
    set -l p (string replace -r '^'(string escape --style=regex -- $HOME) '~' -- $PWD)
    set -l parts (string split '/' -- $p)

    if test (count $parts) -gt 3
        echo ".../"(string join '/' $parts[-3..-1])
    else
        echo $p
    end
end
