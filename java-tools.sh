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
  rm -f ./*.class
}