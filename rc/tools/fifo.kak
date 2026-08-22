provide-module fifo %{

define-command -params .. -docstring %{
    fifo [-name <name>] [-scroll] [-script <script>] [--] <args>...: run command in a fifo buffer
    if <script> is used, eval it with <args> as '$@'; else <args> are quoted and
    evaluated by the shell, with lone operator tokens (| && ; > ...) kept bare so
    pipelines and redirections work
} fifo %{ evaluate-commands %sh{
    name='*fifo*'
    while true; do
        case "$1" in
            "-scroll") scroll="-scroll"; shift ;;
            "-script") script="$2"; shift 2 ;;
            "-name") name="$2"; shift 2 ;;
            "--") shift; break ;;
            *) break ;;
        esac
    done
    output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-fifo.XXXXXXXX)/fifo
    mkfifo ${output}
    if [ -z "$script" ]; then
        for arg do
            case "$arg" in
                '|'|'||'|'&&'|';'|'&'|'>'|'>>'|'<'|'2>'|'2>&1') script="$script $arg" ;;
                *) script="$script '$(printf %s "$arg" | sed "s/'/'\\\\''/g")'" ;;
            esac
        done
    fi
    ( eval "$script" > ${output} 2>&1 & ) > /dev/null 2>&1 < /dev/null

    printf %s\\n "
            edit! -fifo ${output} ${scroll} ${name}
            hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
        "
    }}

complete-command fifo shell

}

hook -once global KakBegin .* %{ require-module fifo }
