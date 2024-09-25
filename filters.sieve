# Define a list of email suffixes
set :global "allowed_suffixes" "
    .edu
    .gov
    .mil
";

# Function to check if an email address ends with any of the allowed suffixes
function "ends_with_allowed_suffix" {
    if allof(
        address :all :matches "${1}" "*@*",
        not string :matches "${1}" ["*${allowed_suffixes}"]
    ) {
        return false;
    }
    return true;
}

# Main filter rule
if not ends_with_allowed_suffix ":from" {
    fileinto "Junk";
    stop;
}
