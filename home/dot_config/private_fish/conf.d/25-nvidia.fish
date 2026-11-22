# NVSHMEM on the DGX Spark: apt installs it outside the default linker path.
# Guarded on the directory, so this is a no-op everywhere else.
set -l nvshmem /usr/lib/aarch64-linux-gnu/nvshmem/13
if test -d $nvshmem
    set -gx --path LD_LIBRARY_PATH $nvshmem $LD_LIBRARY_PATH
end
