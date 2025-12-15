# parser.awk - specific logic to parse bash functions and aliases

# 1. New File Header
# FNR is the "File Record Number". When it resets to 1, we are in a new file.
FNR == 1 {
    # Extract filename from the path for a pretty header
    n = split(FILENAME, parts, "/")
    print "\n\033[1;33m>>> " parts[n] "\033[0m"
}

# 2. Match Aliases
# Looks for lines starting with 'alias '
/^alias / {
    if (show_aliases == "true") {
        print "  \033[36m[ALIAS]\033[0m    " $0
    }
}

# 3. Match Functions
# Regex explanation:
# ^(function +)?   -> Optional 'function' keyword at start
# [a-zA-Z0-9_-]+   -> The function name
# (\(\))?          -> Optional parentheses '()'
#  *\{             -> Space(s) and opening curly brace
/^(function +)?[a-zA-Z0-9_-]+(\(\))? *\{/ {
    if (show_funcs == "true") {
        line = $0
        
        # Clean up the definition line to get just the name
        sub(/^function /, "", line)   # Remove "function " keyword
        sub(/\(\)/, "", line)         # Remove "()"
        sub(/\{/, "", line)           # Remove "{"
        sub(/ +$/, "", line)          # Remove trailing spaces
        
        print "  \033[32m[FUNC]\033[0m     " line

        # 4. Verbose Mode: Extract Comments
        # If verbose is on, we peek at the next lines
        if (verbose == "true") {
            while ((getline doc_line) > 0) {
                # Check if line looks like a comment (whitespace + #)
                if (doc_line ~ /^[ \t]*#/) {
                    # Remove the # and leading whitespace for display
                    sub(/^[ \t]*# ?/, "", doc_line)
                    print "             \033[90m" doc_line "\033[0m"
                } else {
                    # Stop reading if we hit code or an empty line
                    break
                }
            }
        }
    }
}