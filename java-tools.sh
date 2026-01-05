jrun() {
  # Usage: jrun <filename.java> [args...]
  # This function compiles and runs a Java program.
  dep_check "java" || return 1
  dep_check "javac" || return 1
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

  # Extract the bare class name (strip directory path and .java extension)
  local classname
  classname="$(basename "${file%.java}")"
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
    # This function creates a new Java class file with a standard main method boilerplate.
    dep_check "cat" || return 1
    dep_check "subl" || return 1
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

    # Create the file with standard main method boilerplate (no variable expansion)
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
