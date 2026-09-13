function fish_prompt --description 'Port of the zsh PS1: [host] path > '
    set_color blue
    echo -n '['(prompt_hostname)'] '
    set_color green
    echo -n (_prompt_path)
    set_color normal
    echo -n ' > '
end
