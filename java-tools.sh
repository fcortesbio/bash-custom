jrun() {
  if [ -z "$1" ]; then
    echo "Usage: jrun file.java [args...]"
    return 1
  fi

  local file="$1"
  shift 1

  if [[ ! -f "$file" ]]; then
    echo "Error: File '$file' not found"
    return 1
  fi

  local classname="${file%.java}"
  echo "Classname: $classname"

  # Compile
  if ! javac "$file"; then
    echo "Compilation failed"
    return 1
  fi

  # Run
  if ! java "$classname" "$@"; then
    echo "Execution failed"
    rm -f "${classname}.class"
    return 1
  fi

  # Cleanup
  rm -f "${classname}.class"
}

jnew() {
    # Usage: jnew <classname>
    if [ -z "$1" ]; then
        echo "Usage: jnew <classname>"
        return 1
    fi

    local classname="$1"
    local filename="${classname}.java"

    if [ -f "$filename" ]; then
        echo "Error: File '$filename' already exists"
        return 1
    fi

    # Create the file with standard main method boilerplate
    cat <<EOF > "$filename"
public class $classname {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}
EOF
    echo "Created $filename"
    subl "$filename"
}
