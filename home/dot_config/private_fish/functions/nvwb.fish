function nvwb --description 'NVIDIA AI Workbench CLI (fish port of ~/.local/share/nvwb/nvwb-wrapper.sh)'
    set -q NVWB_BIN_PATH; or set -l NVWB_BIN_PATH ~/.nvwb/bin/nvwb-cli

    # activate/deactivate/open/close print bash for the wrapper to eval into
    # the calling shell, unless the last arg asks for help. fish can't eval
    # that, so those go through the real bash wrapper, and you stay in the
    # resulting bash shell (`exit` returns to fish). Anything else is a plain
    # call to the CLI.
    set -l stateful false
    for arg in $argv
        if contains -- $arg activate deactivate open close
            set stateful true
            break
        end
    end
    contains -- "$argv[-1]" -h --help; and set stateful false

    if test $stateful = false
        $NVWB_BIN_PATH $argv
        return
    end

    bash -c 'source ~/.local/share/nvwb/nvwb-wrapper.sh && nvwb "$@" && exec bash -i' nvwb $argv
end
