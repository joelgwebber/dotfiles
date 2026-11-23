# NVSHMEM on the DGX Spark: apt installs it outside the default linker path.
# Guarded on the directory, so this is a no-op everywhere else. Empty entries
# are dropped: zsh's `$dir:$LD_LIBRARY_PATH` leaves a trailing one, which the
# linker reads as the current directory.
set -l nvshmem /usr/lib/aarch64-linux-gnu/nvshmem/13
if test -d $nvshmem
    set -l rest (string match -v -- '' $LD_LIBRARY_PATH)
    contains -- $nvshmem $rest; or set rest $nvshmem $rest
    set -gx --path LD_LIBRARY_PATH $rest
end
